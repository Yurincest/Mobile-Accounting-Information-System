<?php
header('Content-Type: application/json; charset=utf-8');
// CORS untuk akses dari aplikasi web
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}
include 'config.php';
include_once __DIR__ . '/_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonResponse(['status' => 'error', 'message' => 'Invalid request method']);
    exit;
}

try {
    // Data barang terjual bulan ini (agregasi qty per barang)
    $sql = "SELECT mb.KODE_BARANG, mb.NAMA_BARANG, COALESCE(SUM(dn.JUMLAH_BARANG), 0) AS QTY
        FROM JURNAL_UMUM ju
        JOIN DETAIL_NOTA_JUAL dn ON dn.NOMOR_NOTA = ju.REF
        JOIN MSTR_BARANG mb ON mb.KODE_BARANG = dn.KODE_BARANG
        WHERE ju.TANGGAL BETWEEN DATE_FORMAT(NOW(), '%Y-%m-01') AND LAST_DAY(NOW())
        GROUP BY mb.KODE_BARANG, mb.NAMA_BARANG
        ORDER BY QTY DESC, mb.NAMA_BARANG ASC";
    $res = $koneksi->query($sql);
    $rows = [];
    if ($res) {
        while ($row = $res->fetch_assoc()) {
            $row = cleanRow($row);
            $rows[] = [
                'KODE_BARANG' => isset($row['KODE_BARANG']) ? $row['KODE_BARANG'] : '',
                'NAMA_BARANG' => isset($row['NAMA_BARANG']) ? $row['NAMA_BARANG'] : '',
                'QTY' => isset($row['QTY']) ? (int)$row['QTY'] : 0,
            ];
        }
    }
    jsonResponse(['status' => 'success', 'data' => $rows]);
} catch (Throwable $e) {
    http_response_code(500);
    jsonResponse(['status' => 'error', 'message' => $e->getMessage()]);
}
?>