<?php
header('Content-Type: application/json; charset=utf-8');
include 'config.php';
include_once '_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(['status' => 'error', 'message' => 'Invalid request method']);
    exit;
}

$data = $_POST;
if (empty($data)) {
    $raw = file_get_contents('php://input');
    $decoded = json_decode($raw, true);
    if (is_array($decoded)) {
        $data = $decoded;
    }
}

// Gunakan schema ID_* dan JUMLAH_BAYAR/WAKTU_CICIL
if (!isset($data['ID_PIUTANG_CUSTOMER']) || !isset($data['JUMLAH_BAYAR'])) {
    jsonResponse(['status' => 'error', 'message' => 'ID_PIUTANG_CUSTOMER dan JUMLAH_BAYAR wajib diisi']);
    exit;
}

$id_piutang = $data['ID_PIUTANG_CUSTOMER'];
$jumlah_bayar = (float)$data['JUMLAH_BAYAR'];

if ($jumlah_bayar <= 0) {
    jsonResponse(['status' => 'error', 'message' => 'JUMLAH_BAYAR harus lebih dari 0']);
    exit;
}

// Validasi piutang dan sisa berdasarkan akumulasi cicilan (tanpa update kolom SISA/STATUS)
$stmtP = $koneksi->prepare("SELECT JUMLAH_PIUTANG AS TOTAL FROM PIUTANG_CUSTOMER WHERE ID_PIUTANG_CUSTOMER = ?");
$stmtP->bind_param("s", $id_piutang);
$stmtP->execute();
$resP = $stmtP->get_result();
if (!$resP || $resP->num_rows === 0) {
    $stmtP->close();
    jsonResponse(['status' => 'error', 'message' => 'Piutang tidak ditemukan']);
    exit;
}
$rowP = cleanRow($resP->fetch_assoc());
$total_piutang = isset($rowP['TOTAL']) ? (float)$rowP['TOTAL'] : 0.0;
$stmtP->close();

$stmtC = $koneksi->prepare("SELECT COALESCE(SUM(JUMLAH_BAYAR), 0) AS TOTAL_BAYAR FROM TRS_CICILAN_PIUTANG WHERE ID_PIUTANG_CUSTOMER = ?");
$stmtC->bind_param("s", $id_piutang);
$stmtC->execute();
$resC = $stmtC->get_result();
$total_bayar = 0.0;
if ($resC && $resC->num_rows > 0) {
    $r = cleanRow($resC->fetch_assoc());
    $total_bayar = isset($r['TOTAL_BAYAR']) ? (float)$r['TOTAL_BAYAR'] : 0.0;
}
$stmtC->close();

$sisa = max(0.0, $total_piutang - $total_bayar);
if ($jumlah_bayar > $sisa) {
    jsonResponse(['status' => 'error', 'message' => 'Jumlah cicilan melebihi sisa piutang']);
    exit;
}

try {
    // Mulai transaksi
    $koneksi->begin_transaction();

    // Insert cicilan, biarkan trigger mengisi ID_CICILAN_PIUTANG
    $sql_cicilan = "INSERT INTO TRS_CICILAN_PIUTANG (ID_PIUTANG_CUSTOMER, WAKTU_CICIL, JUMLAH_BAYAR) VALUES (?, NOW(), ?)";
    $stmt_c = $koneksi->prepare($sql_cicilan);
    if (!$stmt_c) { throw new Exception("Prepare statement error: " . $koneksi->error); }
    $stmt_c->bind_param("sd", $id_piutang, $jumlah_bayar);
    if (!$stmt_c->execute()) { throw new Exception("Execute error: " . $stmt_c->error); }
    $stmt_c->close();

    // Ambil ID cicilan dari trigger
    $id_cicil = null;
    $sql_get_c = "SELECT ID_CICILAN_PIUTANG FROM TRS_CICILAN_PIUTANG WHERE ID_PIUTANG_CUSTOMER = ? ORDER BY WAKTU_CICIL DESC LIMIT 1";
    $stmt_gc = $koneksi->prepare($sql_get_c);
    if ($stmt_gc) {
        $stmt_gc->bind_param("s", $id_piutang);
        $stmt_gc->execute();
        $resGC = $stmt_gc->get_result();
        if ($resGC && $resGC->num_rows > 0) { $rowGC = cleanRow($resGC->fetch_assoc()); $id_cicil = $rowGC['ID_CICILAN_PIUTANG'] ?? null; }
        $stmt_gc->close();
    }

    // Jurnal untuk cicilan: Debit Kas, Kredit Piutang
    $sql_jurnal = "INSERT INTO JURNAL_UMUM (TANGGAL, REF, KETERANGAN) VALUES (?, ?, ?)";
    $stmt_j = $koneksi->prepare($sql_jurnal);
    if (!$stmt_j) { throw new Exception('Prepare jurnal umum gagal: ' . $koneksi->error); }
    $tanggal_jurnal = date('Y-m-d');
    $keterangan = "Cicilan piutang $id_piutang";
    $ref = $id_piutang;
    $stmt_j->bind_param("sss", $tanggal_jurnal, $ref, $keterangan);
    if (!$stmt_j->execute()) { $stmt_j->close(); throw new Exception("Insert jurnal gagal: " . $stmt_j->error); }
    $stmt_j->close();

    // Ambil ID jurnal dari REF
    $id_jurnal = null;
    $sql_get_j = "SELECT ID_JURNAL_UMUM FROM JURNAL_UMUM WHERE REF = ? ORDER BY CREATED_AT DESC LIMIT 1";
    $stmt_gj = $koneksi->prepare($sql_get_j);
    if ($stmt_gj) {
        $stmt_gj->bind_param("s", $ref);
        $stmt_gj->execute();
        $resGJ = $stmt_gj->get_result();
        if ($resGJ && $resGJ->num_rows > 0) { $rowGJ = cleanRow($resGJ->fetch_assoc()); $id_jurnal = $rowGJ['ID_JURNAL_UMUM'] ?? null; }
        $stmt_gj->close();
    }

    // Detail jurnal: Debit Kas (1001)
    $sql_d = "INSERT INTO JURNAL_DETAIL (ID_JURNAL_UMUM, KODE_AKUN, POSISI, NILAI) VALUES (?, ?, ?, ?)";
    $stmt_d1 = $koneksi->prepare($sql_d);
    if (!$stmt_d1) { throw new Exception('Prepare jurnal detail (debit) gagal: ' . $koneksi->error); }
    $akun_kas = 1001; $posisi_d = 'D'; $nilai_kas = (double)$jumlah_bayar;
    $stmt_d1->bind_param("sisd", $id_jurnal, $akun_kas, $posisi_d, $nilai_kas);
    if (!$stmt_d1->execute()) { $stmt_d1->close(); throw new Exception("Insert jurnal detail (debit) gagal: " . $stmt_d1->error); }
    $stmt_d1->close();

    // Detail jurnal: Kredit Piutang (1101)
    $stmt_d2 = $koneksi->prepare($sql_d);
    if (!$stmt_d2) { throw new Exception('Prepare jurnal detail (kredit) gagal: ' . $koneksi->error); }
    $akun_piutang = 1101; $posisi_k = 'K'; $nilai_piutang = (double)$jumlah_bayar;
    $stmt_d2->bind_param("sisd", $id_jurnal, $akun_piutang, $posisi_k, $nilai_piutang);
    if (!$stmt_d2->execute()) { $stmt_d2->close(); throw new Exception("Insert jurnal detail (kredit) gagal: " . $stmt_d2->error); }
    $stmt_d2->close();

    // Commit agar trigger selesai, lalu tarik STATUS dari DB
    $koneksi->commit();

    // Recalculate totals and status directly from DB
    $stmtP2 = $koneksi->prepare("SELECT JUMLAH_PIUTANG, STATUS FROM PIUTANG_CUSTOMER WHERE ID_PIUTANG_CUSTOMER = ?");
    $stmtP2->bind_param("s", $id_piutang);
    $stmtP2->execute();
    $resP2 = $stmtP2->get_result();
    $jumlah_piutang_db = 0.0; $status_piutang = null;
    if ($resP2 && $resP2->num_rows > 0) {
        $rp2 = cleanRow($resP2->fetch_assoc());
        $jumlah_piutang_db = isset($rp2['JUMLAH_PIUTANG']) ? (float)$rp2['JUMLAH_PIUTANG'] : 0.0;
        $status_piutang = isset($rp2['STATUS']) ? (int)$rp2['STATUS'] : null;
    }
    $stmtP2->close();

    $stmtC2 = $koneksi->prepare("SELECT COALESCE(SUM(JUMLAH_BAYAR), 0) AS TOTAL_BAYAR FROM TRS_CICILAN_PIUTANG WHERE ID_PIUTANG_CUSTOMER = ?");
    $stmtC2->bind_param("s", $id_piutang);
    $stmtC2->execute();
    $resC2 = $stmtC2->get_result();
    $total_bayar_db = 0.0;
    if ($resC2 && $resC2->num_rows > 0) {
        $rc2 = cleanRow($resC2->fetch_assoc());
        $total_bayar_db = isset($rc2['TOTAL_BAYAR']) ? (float)$rc2['TOTAL_BAYAR'] : 0.0;
    }
    $stmtC2->close();

    $sisa_akhir = max(0.0, $jumlah_piutang_db - $total_bayar_db);

    // Jika sisa menjadi 0, pastikan status piutang dan nota ikut LUNAS (0)
    if ($sisa_akhir <= 0.00001) {
        // Update status piutang
        $stmtUpd = $koneksi->prepare("UPDATE PIUTANG_CUSTOMER SET STATUS = 0 WHERE ID_PIUTANG_CUSTOMER = ?");
        if ($stmtUpd) {
            $stmtUpd->bind_param("s", $id_piutang);
            $stmtUpd->execute();
            $stmtUpd->close();
        }
        // Ambil nomor nota dari piutang lalu set status nota LUNAS
        $nota = null;
        $stmtNota = $koneksi->prepare("SELECT NOMOR_NOTA FROM PIUTANG_CUSTOMER WHERE ID_PIUTANG_CUSTOMER = ?");
        if ($stmtNota) {
            $stmtNota->bind_param("s", $id_piutang);
            $stmtNota->execute();
            $resNota = $stmtNota->get_result();
            if ($resNota && $resNota->num_rows > 0) {
                $rN = cleanRow($resNota->fetch_assoc());
                $nota = $rN['NOMOR_NOTA'] ?? null;
            }
            $stmtNota->close();
        }
        if ($nota) {
            $stmtSetNota = $koneksi->prepare("UPDATE NOTA_JUAL SET STATUS = 0 WHERE NOMOR_NOTA = ?");
            if ($stmtSetNota) {
                $stmtSetNota->bind_param("s", $nota);
                $stmtSetNota->execute();
                $stmtSetNota->close();
            }
        }
        $status_piutang = 0;
    }

    $is_lunas = ($sisa_akhir <= 0.00001) ? 1 : 0;

    jsonResponse([
        'status' => 'success',
        'message' => 'Cicilan piutang berhasil ditambahkan',
        'data' => [[
            'ID_CICILAN_PIUTANG' => $id_cicil,
            'ID_JURNAL_UMUM' => $id_jurnal,
            'SISA' => $sisa_akhir,
            'IS_LUNAS' => $is_lunas,
            'STATUS_PIUTANG' => $status_piutang
        ]]
    ]);
    exit;
} catch (Exception $e) {
    if (method_exists($koneksi, 'rollback')) {
        $koneksi->rollback();
    }
    // Pastikan tidak mengembalikan HTTP 500; sampaikan error dalam JSON
    http_response_code(200);
    jsonResponse(['status' => 'error', 'message' => $e->getMessage()]);
    exit;
}

$koneksi->close();
// Tidak menutup tag PHP untuk mencegah output tak sengaja