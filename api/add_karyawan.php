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

if (!isset($data['NIK_KARYAWAN']) || !isset($data['NAMA_KARYAWAN']) || !isset($data['EMAIL']) || !isset($data['PASSWORD'])) {
    jsonResponse(['status' => 'error', 'message' => 'All fields are required']);
    exit;
}

$nik = $data['NIK_KARYAWAN'];
$nama = $data['NAMA_KARYAWAN'];
$email = $data['EMAIL'];
$password = $data['PASSWORD']; // In production, hash this password

$sql = "INSERT INTO KARYAWAN (NIK_KARYAWAN, NAMA_KARYAWAN, EMAIL, PASSWORD) VALUES (?, ?, ?, ?)";
$stmt = $koneksi->prepare($sql);
$stmt->bind_param("ssss", $nik, $nama, $email, $password);

if ($stmt->execute()) {
    jsonResponse(['status' => 'success', 'message' => 'Karyawan berhasil ditambahkan', 'data' => [[
        'NIK_KARYAWAN' => $nik,
        'NAMA_KARYAWAN' => $nama,
        'EMAIL' => $email,
    ]]]);
    exit;
} else {
    jsonResponse(['status' => 'error', 'message' => 'Database query gagal']);
    exit;
}

$stmt->close();
$koneksi->close();