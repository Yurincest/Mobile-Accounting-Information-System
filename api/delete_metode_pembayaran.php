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

if (!isset($data['KODE_METODE'])) {
    jsonResponse(['status' => 'error', 'message' => 'KODE_METODE is required']);
    exit;
}

$kode = $data['KODE_METODE'];

$sql = "DELETE FROM MSTR_METODE_PEMBAYARAN WHERE ID_MPEM = ?";
$stmt = $koneksi->prepare($sql);
$stmt->bind_param("s", $kode);

if ($stmt->execute()) {
    jsonResponse(['status' => 'success', 'message' => 'Metode Pembayaran berhasil dihapus', 'data' => [[
        'KODE_METODE' => $kode,
    ]]]);
    exit;
} else {
    jsonResponse(['status' => 'error', 'message' => 'Database query gagal']);
    exit;
}

$stmt->close();
$koneksi->close();