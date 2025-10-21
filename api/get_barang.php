<?php
header('Content-Type: application/json; charset=utf-8');
include 'config.php';
include_once '_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonResponse(['status' => 'error', 'message' => 'Invalid request method']);
    exit;
}

$sql = "SELECT KODE_BARANG, NAMA_BARANG, HARGA_BARANG, JUMLAH_BARANG, STATUS FROM MSTR_BARANG";
$result = $koneksi->query($sql);

$barang = [];
if ($result && $result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $row = cleanRow($row);
        $barang[] = [
            'KODE_BARANG' => $row['KODE_BARANG'],
            'NAMA_BARANG' => $row['NAMA_BARANG'],
            'HARGA_BARANG' => isset($row['HARGA_BARANG']) ? (float)$row['HARGA_BARANG'] : 0.0,
            'JUMLAH_BARANG' => isset($row['JUMLAH_BARANG']) ? (int)$row['JUMLAH_BARANG'] : 0,
            'STATUS' => isset($row['STATUS']) ? (int)$row['STATUS'] : 0,
        ];
    }
    jsonResponse(['status' => 'success', 'data' => $barang]);
    exit;
} else {
    jsonResponse(['status' => 'error', 'message' => 'Belum ada data']);
    exit;
}

$koneksi->close();