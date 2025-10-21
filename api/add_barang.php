<?php
header('Content-Type: application/json; charset=utf-8');
include 'config.php';
include_once '_helper.php';
include 'generate_code.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(['status' => 'error', 'message' => 'Invalid request method']);
}

// Dukung form-data dan JSON body
$data = $_POST;
if (empty($data)) {
    $data = json_decode(file_get_contents('php://input'), true) ?? [];
}

$nama_barang = $data['NAMA_BARANG'] ?? null;
$harga_barang = $data['HARGA_BARANG'] ?? null;
$stok_barang = $data['JUMLAH_BARANG'] ?? ($data['STOK_BARANG'] ?? null);
$status = $data['STATUS'] ?? null;

if ($nama_barang === null || $harga_barang === null || $stok_barang === null || $status === null) {
    jsonResponse(['status' => 'error', 'message' => 'All fields are required']);
}

$nama_barang = (string)$nama_barang;
$harga_barang = (float)$harga_barang;
$stok_barang = (int)$stok_barang;
$status = (int)$status;
$kode_barang = generateCode('BARANG');

$sql = "INSERT INTO MSTR_BARANG (KODE_BARANG, NAMA_BARANG, HARGA_BARANG, JUMLAH_BARANG, STATUS) VALUES (?, ?, ?, ?, ?)";
/** @var mysqli_stmt $stmt */
$stmt = $koneksi->prepare($sql);
$stmt->bind_param("ssdii", $kode_barang, $nama_barang, $harga_barang, $stok_barang, $status);

if ($stmt->execute()) {
    // Kembalikan data sebagai objek tunggal agar klien Flutter tidak gagal parsing
    jsonResponse(['status' => 'success', 'message' => 'Barang berhasil ditambah', 'data' => [
        'KODE_BARANG' => $kode_barang,
        'NAMA_BARANG' => $nama_barang,
        'HARGA_BARANG' => $harga_barang,
        'JUMLAH_BARANG' => $stok_barang,
        'STATUS' => $status,
    ]]);
    exit;
} else {
    jsonResponse(['status' => 'error', 'message' => 'Database query gagal']);
    exit;
}

$stmt->close();
$koneksi->close();