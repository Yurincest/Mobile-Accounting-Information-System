<?php
header('Content-Type: application/json; charset=utf-8');
include 'config.php';
include_once '_helper.php';

$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['NIK_CUSTOMER']) || !isset($data['NAMA_CUSTOMER']) || !isset($data['EMAIL'])) {
    jsonResponse(['status' => 'error', 'message' => 'All fields are required']);
    exit;
}

$nik = $data['NIK_CUSTOMER'];
$nama = $data['NAMA_CUSTOMER'];
$email = $data['EMAIL'];

$sql = "UPDATE CUSTOMER SET NAMA_CUSTOMER = ?, EMAIL = ? WHERE NIK_CUSTOMER = ?";
$stmt = $koneksi->prepare($sql);
$stmt->bind_param("sss", $nama, $email, $nik);

if ($stmt->execute()) {
    jsonResponse(['status' => 'success', 'message' => 'Customer updated successfully', 'data' => [[
        'NIK_CUSTOMER' => $nik,
        'NAMA_CUSTOMER' => $nama,
        'EMAIL' => $email,
    ]]]);
    exit;
} else {
    jsonResponse(['status' => 'error', 'message' => $stmt->error]);
    exit;
}

$stmt->close();
$koneksi->close();