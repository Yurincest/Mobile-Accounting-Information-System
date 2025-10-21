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
    $data = json_decode(file_get_contents('php://input'), true) ?? [];
}

// Terima baik form-data maupun JSON
$nik_customer = $data['NIK_CUSTOMER'] ?? '';
$nik_karyawan = $data['NIK_KARYAWAN'] ?? '';
$id_mpem = $data['ID_MPEM'] ?? ($data['KODE_METODE'] ?? '');
$tanggal = $data['TANGGAL'] ?? date('Y-m-d');
$detail_items = $data['DETAIL_ITEMS'] ?? [];

// Validasi data sesuai skema baru
if (empty($nik_customer) || empty($nik_karyawan) || empty($id_mpem) || empty($tanggal) || empty($detail_items)) {
    jsonResponse(['status' => 'error', 'message' => 'Data tidak lengkap (NIK_CUSTOMER, NIK_KARYAWAN, ID_MPEM/KODE_METODE, TANGGAL, DETAIL_ITEMS)']);
    exit;
}

// Validasi customer
$stmt = $koneksi->prepare("SELECT * FROM CUSTOMER WHERE NIK_CUSTOMER = ?");
$stmt->bind_param("s", $nik_customer);
$stmt->execute();
$result = $stmt->get_result();
if ($result->num_rows == 0) {
    jsonResponse(['status' => 'error', 'message' => 'Customer tidak ditemukan']);
    $stmt->close();
    $koneksi->close();
    exit;
}
$stmt->close();

// Validasi metode pembayaran (gunakan ID_MPEM)
$stmt = $koneksi->prepare("SELECT ID_MPEM, NAMA_MPEM FROM MSTR_METODE_PEMBAYARAN WHERE ID_MPEM = ?");
$stmt->bind_param("s", $id_mpem);
$stmt->execute();
$result = $stmt->get_result();
if ($result->num_rows == 0) {
    jsonResponse(['status' => 'error', 'message' => 'Metode pembayaran tidak ditemukan']);
    $stmt->close();
    $koneksi->close();
    exit;
}
$stmt->close();

// Biarkan trigger database mengenerate NOMOR_NOTA (prefix NOTxxxxxxx)
// NOMOR_NOTA akan diambil setelah insert

// Mulai transaksi
$koneksi->begin_transaction();

try {
    // Ambil DP dari payload (default 0) dan generate NOMOR_NOTA di sisi PHP agar deterministik
    $dp = isset($data['DP']) ? (double)$data['DP'] : 0.0;
    $nomor_nota = 'NOT' . strtoupper(str_pad(dechex(random_int(0, 0xFFFFFFF)), 7, '0', STR_PAD_LEFT));

    // Insert ke NOTA_JUAL dengan NOMOR_NOTA eksplisit (tidak bergantung SELECT terbaru)
    $sql_nota = "INSERT INTO NOTA_JUAL (NOMOR_NOTA, NIK_CUSTOMER, NIK_KARYAWAN, ID_MPEM) VALUES (?, ?, ?, ?)";
    $stmt_nota = $koneksi->prepare($sql_nota);
    if (!$stmt_nota) { throw new Exception("Prepare insert nota gagal: " . $koneksi->error); }
    $stmt_nota->bind_param("ssss", $nomor_nota, $nik_customer, $nik_karyawan, $id_mpem);
    if (!$stmt_nota->execute()) { throw new Exception("Insert nota gagal: " . $stmt_nota->error); }
    $stmt_nota->close();

    // NOMOR_NOTA sudah ditentukan di atas; tidak perlu SELECT berdasarkan kombinasi non-unik
    
    // Hitung total transaksi berdasarkan harga barang x jumlah
    $totalTransaksi = 0.0;
    
    // Insert detail nota (skema baru)
    foreach ($detail_items as $item) {
        $kode_barang = $item['KODE_BARANG'] ?? '';
        $qty = (int)($item['QTY'] ?? ($item['JUMLAH_BARANG'] ?? 0));
        
        // Validasi barang dan stok
        $stmt_barang = $koneksi->prepare("SELECT HARGA_BARANG, JUMLAH_BARANG FROM MSTR_BARANG WHERE KODE_BARANG = ?");
        $stmt_barang->bind_param("s", $kode_barang);
        $stmt_barang->execute();
        $result_barang = $stmt_barang->get_result();
        if ($result_barang->num_rows == 0) {
            throw new Exception("Barang dengan kode $kode_barang tidak ditemukan");
        }
        $barang_data = cleanRow($result_barang->fetch_assoc());
        $stmt_barang->close();
        
        if ((int)$barang_data['JUMLAH_BARANG'] < $qty) {
            throw new Exception("Jumlah barang $kode_barang tidak mencukupi");
        }
        
        // Tambah total transaksi
        $harga_barang = (float)$barang_data['HARGA_BARANG'];
        $totalTransaksi += ($harga_barang * $qty);
        
        // Insert detail (NOMOR_NOTA, KODE_BARANG, JUMLAH_BARANG)
        $sql_detail = "INSERT INTO DETAIL_NOTA_JUAL (NOMOR_NOTA, KODE_BARANG, JUMLAH_BARANG) VALUES (?, ?, ?)";
        $stmt_detail = $koneksi->prepare($sql_detail);
        $stmt_detail->bind_param("ssi", $nomor_nota, $kode_barang, $qty);
        if (!$stmt_detail->execute()) {
            throw new Exception("Database query gagal (insert detail)");
        }
        $stmt_detail->close();
        
        // Update stok barang
        $sql_update_stok = "UPDATE MSTR_BARANG SET JUMLAH_BARANG = JUMLAH_BARANG - ? WHERE KODE_BARANG = ?";
        $stmt_stok = $koneksi->prepare($sql_update_stok);
        $stmt_stok->bind_param("is", $qty, $kode_barang);
        if (!$stmt_stok->execute()) {
            throw new Exception("Database query gagal (update stok)");
        }
        $stmt_stok->close();
    }
    
    // Tentukan metode pembayaran dan buat piutang bila Kredit/Piutang
    $nama_metode = null;
    $stmtM = $koneksi->prepare("SELECT NAMA_MPEM FROM MSTR_METODE_PEMBAYARAN WHERE ID_MPEM = ?");
    if ($stmtM) {
        $stmtM->bind_param("s", $id_mpem);
        $stmtM->execute();
        $resM = $stmtM->get_result();
        if ($resM && $resM->num_rows > 0) { $rowM = cleanRow($resM->fetch_assoc()); $nama_metode = $rowM['NAMA_MPEM'] ?? null; }
        $stmtM->close();
    }

    // Debug: log nama metode untuk troubleshooting
    error_log("DEBUG: ID_MPEM = $id_mpem, NAMA_MPEM = " . ($nama_metode ?? 'NULL'));

    $id_piutang = null;
    $method = strtolower((string)$nama_metode);
    $isCashLike = ($method === 'cash' || $method === 'transfer' || $method === 'transfer bank');
    $isCredit = ($method === 'kredit' || $method === 'credit' || $method === 'piutang' || $method === 'kredit/piutang');
    
    // Debug: log hasil pengecekan metode
    error_log("DEBUG: method = '$method', isCashLike = " . ($isCashLike ? 'true' : 'false') . ", isCredit = " . ($isCredit ? 'true' : 'false'));
    
    if ($isCredit) {
        // Hitung jumlah piutang: TOTAL - DP, minimal 0
        $jumlah_piutang_tx = max(0.0, (double)$totalTransaksi - (double)$dp);
        
        // Debug: log jumlah piutang
        error_log("DEBUG: totalTransaksi = $totalTransaksi, dp = $dp, jumlah_piutang_tx = $jumlah_piutang_tx");
        
        // Non-cash: pastikan hanya ada SATU piutang per NOMOR_NOTA
        // Jika sudah ada, lakukan UPDATE; jika belum ada, lakukan INSERT
        $sql_check = "SELECT ID_PIUTANG_CUSTOMER FROM PIUTANG_CUSTOMER WHERE NOMOR_NOTA = ? LIMIT 1";
        $stmt_chk = $koneksi->prepare($sql_check);
        if (!$stmt_chk) { throw new Exception('Prepare cek piutang gagal: ' . $koneksi->error); }
        $stmt_chk->bind_param("s", $nomor_nota);
        $stmt_chk->execute();
        $res_chk = $stmt_chk->get_result();
        if ($res_chk && $res_chk->num_rows > 0) {
            // Sudah ada piutang untuk nota ini -> update jumlah dan set status belum lunas (1)
            $row_chk = cleanRow($res_chk->fetch_assoc());
            $id_piutang = $row_chk['ID_PIUTANG_CUSTOMER'] ?? null;
            $stmt_upd = $koneksi->prepare("UPDATE PIUTANG_CUSTOMER SET JUMLAH_PIUTANG = ?, STATUS = 1 WHERE ID_PIUTANG_CUSTOMER = ?");
            if (!$stmt_upd) { throw new Exception('Prepare update piutang gagal: ' . $koneksi->error); }
            $stmt_upd->bind_param("ds", $jumlah_piutang_tx, $id_piutang);
            if (!$stmt_upd->execute()) { $stmt_upd->close(); throw new Exception('Update piutang gagal: ' . $stmt_upd->error); }
            $stmt_upd->close();
        } else {
            // Belum ada piutang -> insert baru
            $sql_piutang = "INSERT INTO PIUTANG_CUSTOMER (NOMOR_NOTA, JUMLAH_PIUTANG, STATUS) VALUES (?, ?, 1)";
            $stmt_piutang = $koneksi->prepare($sql_piutang);
            if (!$stmt_piutang) { throw new Exception('Prepare insert piutang gagal: ' . $koneksi->error); }
            $stmt_piutang->bind_param("sd", $nomor_nota, $jumlah_piutang_tx);
            if (!$stmt_piutang->execute()) { $stmt_piutang->close(); throw new Exception('Insert piutang gagal: ' . $stmt_piutang->error); }
            $stmt_piutang->close();

            // Ambil ID piutang dari trigger
            $sql_get_piutang = "SELECT ID_PIUTANG_CUSTOMER FROM PIUTANG_CUSTOMER WHERE NOMOR_NOTA = ? ORDER BY ID_PIUTANG_CUSTOMER DESC LIMIT 1";
            $stmt_gp = $koneksi->prepare($sql_get_piutang);
            if ($stmt_gp) {
                $stmt_gp->bind_param("s", $nomor_nota);
                $stmt_gp->execute();
                $resGP = $stmt_gp->get_result();
                if ($resGP && $resGP->num_rows > 0) { $gpRow = cleanRow($resGP->fetch_assoc()); $id_piutang = $gpRow['ID_PIUTANG_CUSTOMER'] ?? null; }
                $stmt_gp->close();
            }
        }

        // Set STATUS nota untuk kredit = 1 (belum lunas)
        $stmt_set_credit = $koneksi->prepare("UPDATE NOTA_JUAL SET STATUS = 1 WHERE NOMOR_NOTA = ?");
        if ($stmt_set_credit) {
            $stmt_set_credit->bind_param("s", $nomor_nota);
            $stmt_set_credit->execute();
            $stmt_set_credit->close();
        }

    } else {
        // Cash/Transfer: tidak ada piutang; set STATUS nota langsung LUNAS (0)
        $stmt_set = $koneksi->prepare("UPDATE NOTA_JUAL SET STATUS = 0 WHERE NOMOR_NOTA = ?");
        if ($stmt_set) {
            $stmt_set->bind_param("s", $nomor_nota);
            $stmt_set->execute();
            $stmt_set->close();
        }
    }
    
    // Buat jurnal umum untuk transaksi (ID di-generate trigger JURxxxxxxx)
    $sql_jurnal = "INSERT INTO JURNAL_UMUM (TANGGAL, REF, KETERANGAN) VALUES (?, ?, ?)";
    $stmt_jurnal = $koneksi->prepare($sql_jurnal);
    if (!$stmt_jurnal) { throw new Exception('Prepare insert jurnal gagal: ' . $koneksi->error); }
    $keterangan = "Penjualan $nomor_nota";
    $stmt_jurnal->bind_param("sss", $tanggal, $nomor_nota, $keterangan);
    if (!$stmt_jurnal->execute()) { $stmt_jurnal->close(); throw new Exception('Insert jurnal gagal: ' . $stmt_jurnal->error); }
    $stmt_jurnal->close();

    // Ambil ID jurnal dari REF
    $id_jurnal = null;
    $sql_get_j = "SELECT ID_JURNAL_UMUM FROM JURNAL_UMUM WHERE REF = ? ORDER BY CREATED_AT DESC LIMIT 1";
    $stmt_gj = $koneksi->prepare($sql_get_j);
    if ($stmt_gj) {
        $stmt_gj->bind_param("s", $nomor_nota);
        $stmt_gj->execute();
        $resGJ = $stmt_gj->get_result();
        if ($resGJ && $resGJ->num_rows > 0) { $gjRow = cleanRow($resGJ->fetch_assoc()); $id_jurnal = $gjRow['ID_JURNAL_UMUM'] ?? null; }
        $stmt_gj->close();
    }
    
    // Detail jurnal
    // Jika kredit dengan DP: pecah debit menjadi Kas (DP) + Piutang (sisa)
    $sql_jd = "INSERT INTO JURNAL_DETAIL (ID_JURNAL_UMUM, KODE_AKUN, POSISI, NILAI) VALUES (?, ?, ?, ?)";
    if ($isCredit && ((double)$dp > 0.0)) {
        $sisaPiutangJurnal = max(0.0, (double)$totalTransaksi - (double)$dp);

        // Debit Kas untuk nilai DP
        if ((double)$dp > 0.0) {
            $stmt_d_cash = $koneksi->prepare($sql_jd);
            if (!$stmt_d_cash) { throw new Exception('Prepare jurnal detail (debit kas DP) gagal: ' . $koneksi->error); }
            $akun_kas = 1001; $pos_d_cash = 'D'; $nilai_d_cash = (double)$dp;
            $stmt_d_cash->bind_param("sisd", $id_jurnal, $akun_kas, $pos_d_cash, $nilai_d_cash);
            if (!$stmt_d_cash->execute()) { $stmt_d_cash->close(); throw new Exception('Insert jurnal detail (debit kas DP) gagal: ' . $stmt_d_cash->error); }
            $stmt_d_cash->close();
        }

        // Debit Piutang untuk sisa
        if ($sisaPiutangJurnal > 0.0) {
            $stmt_d_piutang = $koneksi->prepare($sql_jd);
            if (!$stmt_d_piutang) { throw new Exception('Prepare jurnal detail (debit piutang sisa) gagal: ' . $koneksi->error); }
            $akun_piutang = 1101; $pos_d_piutang = 'D'; $nilai_d_piutang = $sisaPiutangJurnal;
            $stmt_d_piutang->bind_param("sisd", $id_jurnal, $akun_piutang, $pos_d_piutang, $nilai_d_piutang);
            if (!$stmt_d_piutang->execute()) { $stmt_d_piutang->close(); throw new Exception('Insert jurnal detail (debit piutang sisa) gagal: ' . $stmt_d_piutang->error); }
            $stmt_d_piutang->close();
        }
    } else {
        // Tanpa DP: satu baris debit (Kas untuk cash/transfer, Piutang untuk kredit penuh)
        $akun_debit = $isCashLike ? 1001 : 1101;
        $pos_d = 'D'; $nilai_d = (double)$totalTransaksi;
        $stmt_d1 = $koneksi->prepare($sql_jd);
        if (!$stmt_d1) { throw new Exception('Prepare jurnal detail (debit) gagal: ' . $koneksi->error); }
        $stmt_d1->bind_param("sisd", $id_jurnal, $akun_debit, $pos_d, $nilai_d);
        if (!$stmt_d1->execute()) { $stmt_d1->close(); throw new Exception('Insert jurnal detail (debit) gagal: ' . $stmt_d1->error); }
        $stmt_d1->close();
    }
    
    // Detail jurnal - Kredit Pendapatan
    $stmt_k = $koneksi->prepare($sql_jd);
    if (!$stmt_k) { throw new Exception('Prepare jurnal detail (kredit) gagal: ' . $koneksi->error); }
    $akun_pendapatan = 4001; $pos_k = 'K'; $nilai_k = (double)$totalTransaksi;
    $stmt_k->bind_param("sisd", $id_jurnal, $akun_pendapatan, $pos_k, $nilai_k);
    if (!$stmt_k->execute()) { $stmt_k->close(); throw new Exception('Insert jurnal detail (kredit) gagal: ' . $stmt_k->error); }
    $stmt_k->close();
    
    // Commit transaksi
    $koneksi->commit();
    
    jsonResponse([
        'status' => 'success',
        'message' => 'Nota jual berhasil dibuat',
        'data' => [[
            'NOMOR_NOTA' => $nomor_nota,
            'ID_PIUTANG_CUSTOMER' => $id_piutang,
            'ID_JURNAL_UMUM' => $id_jurnal,
            'STATUS_NOTA' => strtolower((string)$nama_metode) !== 'cash' ? 1 : 0
        ]]
    ]);
    exit;
    
} catch (Exception $e) {
    // Rollback jika ada error
    if (method_exists($koneksi, 'rollback')) { $koneksi->rollback(); }
    http_response_code(200);
    jsonResponse(['status' => 'error', 'message' => $e->getMessage()]);
    exit;
}

$koneksi->close();
// Tidak menutup tag PHP untuk mencegah output tak sengaja
