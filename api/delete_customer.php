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

if (!isset($data['NIK_CUSTOMER'])) {
    jsonResponse(['status' => 'error', 'message' => 'NIK_CUSTOMER is required']);
    exit;
}

$nik = $data['NIK_CUSTOMER'];

$sql = "DELETE FROM CUSTOMER WHERE NIK_CUSTOMER = ?";
$stmt = $koneksi->prepare($sql);
$stmt->bind_param("s", $nik);

if ($stmt->execute()) {
    jsonResponse(['status' => 'success', 'message' => 'Customer berhasil dihapus', 'data' => [[
        'NIK_CUSTOMER' => $nik,
    ]]]);
    exit;
} else {
    jsonResponse(['status' => 'error', 'message' => 'Database query gagal']);
    exit;
}

$stmt->close();
$koneksi->close();