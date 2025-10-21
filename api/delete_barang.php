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

if (!isset($data['KODE_BARANG'])) {
    jsonResponse(['status' => 'error', 'message' => 'KODE_BARANG is required']);
    exit;
}

$kode = $data['KODE_BARANG'];

$sql = "DELETE FROM MSTR_BARANG WHERE KODE_BARANG = ?";
/** @var mysqli_stmt $stmt */
$stmt = $koneksi->prepare($sql);
$stmt->bind_param("s", $kode);

if ($stmt->execute()) {
    jsonResponse(['status' => 'success', 'message' => 'Barang berhasil dihapus', 'data' => [[
        'KODE_BARANG' => $kode,
    ]]]);
    exit;
} else {
    jsonResponse(['status' => 'error', 'message' => 'Database query gagal']);
    exit;
}

$stmt->close();
$koneksi->close();