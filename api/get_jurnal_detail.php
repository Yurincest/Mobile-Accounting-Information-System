<?php
header('Content-Type: application/json; charset=utf-8');
include 'config.php';
include_once '_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonResponse(['status' => 'error', 'message' => 'Invalid request method']);
    exit;
}

// Gunakan parameter ID_JURNAL_UMUM sesuai instruksi
$id_jurnal_umum = $_GET['ID_JURNAL_UMUM'] ?? '';
if (empty($id_jurnal_umum)) {
    jsonResponse(['status' => 'error', 'message' => 'ID_JURNAL_UMUM diperlukan']);
    exit;
}

// Query join JURNAL_DETAIL + JURNAL_UMUM + KODE_AKUN
$sql = "SELECT jd.ID_DETAIL, jd.ID_JURNAL_UMUM, jd.KODE_AKUN, ka.NAMA_AKUN, jd.POSISI, jd.NILAI
        FROM JURNAL_DETAIL jd
        JOIN JURNAL_UMUM ju ON jd.ID_JURNAL_UMUM = ju.ID_JURNAL_UMUM
        JOIN KODE_AKUN ka ON jd.KODE_AKUN = ka.KODE_AKUN
        WHERE jd.ID_JURNAL_UMUM = ?";
$stmt = $koneksi->prepare($sql);
if (!$stmt) {
    jsonResponse(['status' => 'error', 'message' => 'Prepare gagal: ' . $koneksi->error]);
    exit;
}
$stmt->bind_param("s", $id_jurnal_umum);
$stmt->execute();
$result = $stmt->get_result();

$details = [];
if ($result && $result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $row = cleanRow($row);
        // Sanitasi newline agar JSON tidak pecah di client log
        if (isset($row['NAMA_AKUN'])) {
            $row['NAMA_AKUN'] = str_replace(["\r","\n"], ' ', $row['NAMA_AKUN']);
        }
        $details[] = [
            'ID_DETAIL' => $row['ID_DETAIL'] ?? null,
            'ID_JURNAL_UMUM' => $row['ID_JURNAL_UMUM'] ?? null,
            'KODE_AKUN' => $row['KODE_AKUN'] ?? null,
            'NAMA_AKUN' => $row['NAMA_AKUN'] ?? null,
            'DEBIT' => (isset($row['POSISI']) && $row['POSISI'] === 'D') ? (double)$row['NILAI'] : 0.0,
            'KREDIT' => (isset($row['POSISI']) && $row['POSISI'] === 'K') ? (double)$row['NILAI'] : 0.0,
        ];
    }

    // Tambahkan detail per barang jika REF adalah nomor nota (NOTxxxxx)
    $refNota = null;
    $stmtRef = $koneksi->prepare("SELECT REF FROM JURNAL_UMUM WHERE ID_JURNAL_UMUM = ? LIMIT 1");
    if ($stmtRef) {
        $stmtRef->bind_param("s", $id_jurnal_umum);
        $stmtRef->execute();
        $resRef = $stmtRef->get_result();
        if ($resRef && $resRef->num_rows > 0) {
            $rowRef = cleanRow($resRef->fetch_assoc());
            $refNota = $rowRef['REF'] ?? null;
        }
        $stmtRef->close();
    }

    if (!empty($refNota) && strpos($refNota, 'NOT') === 0) {
        $sqlItems = "SELECT dn.KODE_BARANG, mb.NAMA_BARANG, dn.JUMLAH_BARANG, mb.HARGA_BARANG,
                            (dn.JUMLAH_BARANG * mb.HARGA_BARANG) AS SUBTOTAL
                      FROM DETAIL_NOTA_JUAL dn
                      JOIN MSTR_BARANG mb ON mb.KODE_BARANG = dn.KODE_BARANG
                      WHERE dn.NOMOR_NOTA = ?";
        $stmtItems = $koneksi->prepare($sqlItems);
        if ($stmtItems) {
            $stmtItems->bind_param("s", $refNota);
            $stmtItems->execute();
            $resItems = $stmtItems->get_result();
            if ($resItems && $resItems->num_rows > 0) {
                while ($ri = $resItems->fetch_assoc()) {
                    $ri = cleanRow($ri);
                    // Baris pseudo-akun untuk menampilkan barang dan subtotalnya di UI
                    $namaAkun = (isset($ri['NAMA_BARANG']) ? $ri['NAMA_BARANG'] : '') .
                                ' (Qty ' . (int)($ri['JUMLAH_BARANG'] ?? 0) .
                                ' x ' . (isset($ri['HARGA_BARANG']) ? (double)$ri['HARGA_BARANG'] : 0.0) . ')';
                    $details[] = [
                        'ID_DETAIL' => null,
                        'ID_JURNAL_UMUM' => $id_jurnal_umum,
                        'KODE_AKUN' => 'BARANG: ' . ($ri['KODE_BARANG'] ?? ''),
                        'NAMA_AKUN' => $namaAkun,
                        'DEBIT' => isset($ri['SUBTOTAL']) ? (double)$ri['SUBTOTAL'] : 0.0,
                        'KREDIT' => 0.0,
                    ];
                }
            }
            $stmtItems->close();
        }
    }

    jsonResponse(['status' => 'success', 'data' => $details]);
    exit;
} else {
    jsonResponse(['status' => 'error', 'message' => 'Belum ada data']);
    exit;
}

if (isset($stmt)) { $stmt->close(); }
$koneksi->close();
// Tidak menutup tag PHP untuk mencegah output tak sengaja