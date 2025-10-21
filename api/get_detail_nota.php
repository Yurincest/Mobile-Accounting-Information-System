<?php
header('Content-Type: application/json; charset=utf-8');
include 'config.php';
include_once '_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonResponse(['status' => 'error', 'message' => 'Invalid request method']);
    exit;
}

$kode_nota = $_GET['KODE_NOTA'] ?? '';

if (empty($kode_nota)) {
    jsonResponse(['status' => 'error', 'message' => 'Kode nota diperlukan']);
    exit;
}

// Menyesuaikan dengan skema baru: gunakan NOMOR_NOTA dan hitung HARGA & SUBTOTAL dari MSTR_BARANG
$sql = "SELECT dn.NOMOR_NOTA, dn.KODE_BARANG, mb.NAMA_BARANG, dn.JUMLAH_BARANG, mb.HARGA_BARANG,
               (dn.JUMLAH_BARANG * mb.HARGA_BARANG) AS SUBTOTAL
        FROM DETAIL_NOTA_JUAL dn
        JOIN MSTR_BARANG mb ON mb.KODE_BARANG = dn.KODE_BARANG
        WHERE dn.NOMOR_NOTA = ?";
$stmt = $koneksi->prepare($sql);
$stmt->bind_param("s", $kode_nota);
$stmt->execute();
$result = $stmt->get_result();

$details = [];
if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $row = cleanRow($row);
        // Alias kolom ke schema JSON lama agar Flutter tetap kompatibel
        $details[] = [
            'KODE_NOTA' => $row['NOMOR_NOTA'],
            'KODE_BARANG' => $row['KODE_BARANG'],
            'NAMA_BARANG' => $row['NAMA_BARANG'],
            'QTY' => (int)$row['JUMLAH_BARANG'],
            'HARGA' => isset($row['HARGA_BARANG']) ? (double)$row['HARGA_BARANG'] : 0.0,
            'SUBTOTAL' => isset($row['SUBTOTAL']) ? (double)$row['SUBTOTAL'] : 0.0,
        ];
    }
    jsonResponse(['status' => 'success', 'data' => $details]);
    exit;
} else {
    jsonResponse(['status' => 'error', 'message' => 'Belum ada data']);
    exit;
}

$stmt->close();
$koneksi->close();
// Tidak menutup tag PHP untuk mencegah output tak sengaja