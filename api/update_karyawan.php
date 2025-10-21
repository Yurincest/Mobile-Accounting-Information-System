<?php
header('Content-Type: application/json');
include 'config.php';
include_once '_helper.php';

$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['NIK_KARYAWAN']) || !isset($data['NAMA_KARYAWAN']) || !isset($data['EMAIL']) || !isset($data['PASSWORD'])) {
    jsonResponse(['status' => 'error', 'message' => 'All fields are required']);
    exit;
}

$nik = $data['NIK_KARYAWAN'];
$nama = $data['NAMA_KARYAWAN'];
$email = $data['EMAIL'];
$password = $data['PASSWORD'];

$sql = "UPDATE KARYAWAN SET NAMA_KARYAWAN = ?, EMAIL = ?, PASSWORD = ? WHERE NIK_KARYAWAN = ?";
$stmt = $koneksi->prepare($sql);
$stmt->bind_param("ssss", $nama, $email, $password, $nik); // Ubah bind_param ke ssss asumsi NIK string

if ($stmt->execute()) {
    jsonResponse(['status' => 'success', 'message' => 'Karyawan updated successfully', 'data' => [[
        'NIK_KARYAWAN' => $nik,
        'NAMA_KARYAWAN' => $nama,
        'EMAIL' => $email,
    ]]]);
    exit;
} else {
    jsonResponse(['status' => 'error', 'message' => $stmt->error]);
    exit;
}

$stmt->close();
$koneksi->close();