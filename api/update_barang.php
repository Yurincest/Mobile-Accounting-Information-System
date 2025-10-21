<?php
header('Content-Type: application/json');
include 'config.php';
include_once '_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(['status' => 'error', 'message' => 'Invalid request method']);
    exit;
}

// Dukung form-data dan JSON body
$data = $_POST;
if (empty($data)) {
    $data = json_decode(file_get_contents('php://input'), true) ?? [];
}

$kode_barang = $data['KODE_BARANG'] ?? null;
$nama_barang = $data['NAMA_BARANG'] ?? null;
$harga_barang = $data['HARGA_BARANG'] ?? null;
$stok_barang = $data['JUMLAH_BARANG'] ?? ($data['STOK_BARANG'] ?? null);
$status = $data['STATUS'] ?? null;

if ($kode_barang === null || $nama_barang === null || $harga_barang === null || $stok_barang === null || $status === null) {
    jsonResponse(['status' => 'error', 'message' => 'All fields are required']);
    exit;
}

$nama_barang = (string)$nama_barang;
$harga_barang = (float)$harga_barang;
$stok_barang = (int)$stok_barang;
$status = (int)$status;

$sql = "UPDATE MSTR_BARANG SET NAMA_BARANG = ?, HARGA_BARANG = ?, JUMLAH_BARANG = ?, STATUS = ? WHERE KODE_BARANG = ?";
/** @var mysqli_stmt $stmt */
$stmt = $koneksi->prepare($sql);
$stmt->bind_param("sdiis", $nama_barang, $harga_barang, $stok_barang, $status, $kode_barang);

if ($stmt->execute()) {
    jsonResponse(['status' => 'success', 'message' => 'Barang updated successfully', 'data' => [[
        'KODE_BARANG' => $kode_barang,
        'NAMA_BARANG' => $nama_barang,
        'HARGA_BARANG' => $harga_barang,
        'JUMLAH_BARANG' => $stok_barang,
        'STATUS' => $status,
    ]]]);
    exit;
} else {
    jsonResponse(['status' => 'error', 'message' => $stmt->error]);
    exit;
}

$stmt->close();
$koneksi->close();