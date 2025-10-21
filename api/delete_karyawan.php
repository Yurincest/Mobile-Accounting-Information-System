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

if (!isset($data['NIK_KARYAWAN'])) {
    jsonResponse(['status' => 'error', 'message' => 'NIK_KARYAWAN is required']);
    exit;
}

$nik = $data['NIK_KARYAWAN'];

$sql = "DELETE FROM KARYAWAN WHERE NIK_KARYAWAN = ?";
$stmt = $koneksi->prepare($sql);
$stmt->bind_param("s", $nik);

if ($stmt->execute()) {
    jsonResponse(['status' => 'success', 'message' => 'Karyawan berhasil dihapus', 'data' => [[
        'NIK_KARYAWAN' => $nik,
    ]]]);
    exit;
} else {
    jsonResponse(['status' => 'error', 'message' => 'Database query gagal']);
    exit;
}

$stmt->close();
$koneksi->close();