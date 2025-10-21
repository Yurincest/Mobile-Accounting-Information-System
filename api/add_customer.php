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

if (!isset($data['NIK_CUSTOMER']) || !isset($data['NAMA_CUSTOMER']) || !isset($data['EMAIL'])) {
    jsonResponse(['status' => 'error', 'message' => 'All fields are required']);
    exit;
}

$nik_customer = $data['NIK_CUSTOMER'];
$nama_customer = $data['NAMA_CUSTOMER'];
$email = $data['EMAIL'];

// Validasi unik NIK_CUSTOMER
$checkSql = "SELECT 1 FROM CUSTOMER WHERE NIK_CUSTOMER = ? LIMIT 1";
$checkStmt = $koneksi->prepare($checkSql);
if (!$checkStmt) {
    jsonResponse(['status' => 'error', 'message' => 'Prepare check failed: ' . $koneksi->error]);
}
$checkStmt->bind_param("s", $nik_customer);
$checkStmt->execute();
$checkStmt->store_result();
if ($checkStmt->num_rows > 0) {
    $checkStmt->close();
    jsonResponse(['status' => 'error', 'code' => 'duplicate_nik', 'message' => 'NIK Customer sudah terdaftar']);
    exit;
}
$checkStmt->close();

$sql = "INSERT INTO CUSTOMER (NIK_CUSTOMER, NAMA_CUSTOMER, EMAIL) VALUES (?, ?, ?)";
$stmt = $koneksi->prepare($sql);
$stmt->bind_param("sss", $nik_customer, $nama_customer, $email);

if ($stmt->execute()) {
    jsonResponse(['status' => 'success', 'message' => 'Customer berhasil ditambahkan', 'data' => [[
        'NIK_CUSTOMER' => $nik_customer,
        'NAMA_CUSTOMER' => $nama_customer,
        'EMAIL' => $email,
    ]]]);
    exit;
} else {
    jsonResponse(['status' => 'error', 'message' => 'Database query gagal: ' . $stmt->error]);
    exit;
}

$stmt->close();
$koneksi->close();