<?php
header('Content-Type: application/json; charset=utf-8');
include 'config.php';
include 'generate_code.php';
include_once '_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(['status' => 'error', 'message' => 'Invalid request method']);
    exit;
}

$data = $_POST;
if (empty($data)) {
    $data = json_decode(file_get_contents('php://input'), true) ?? [];
}

// Validasi minimum: hanya field master
if (!isset($data['NAMA_MEMBERSHIP']) || !isset($data['HARGA_MEMBERSHIP']) || !isset($data['POTONGAN']) || !isset($data['STATUS'])) {
    jsonResponse(['status' => 'error', 'message' => 'Fields NAMA_MEMBERSHIP, HARGA_MEMBERSHIP, POTONGAN, STATUS wajib']);
    exit;
}

$id_master_membership = generateCode('MBR');
// Abaikan customer di request; fokus master-only
$nik_customer = null; // pastikan NULL dikirim bila kolom mengizinkan NULL
$nama_membership = $data['NAMA_MEMBERSHIP'];
$harga_membership = (double)$data['HARGA_MEMBERSHIP'];
$potongan = (int)$data['POTONGAN'];
$status = (int)$data['STATUS'];

$koneksi->begin_transaction();
$sql = "INSERT INTO MASTER_MEMBERSHIP (ID_MASTER_MEMBERSHIP, NIK_CUSTOMER, NAMA_MEMBERSHIP, HARGA_MEMBERSHIP, POTONGAN, STATUS, LAST_UPDATED) 
        VALUES (?, ?, ?, ?, ?, ?, NOW())";
$stmt = $koneksi->prepare($sql);
$stmt->bind_param("sssdii", $id_master_membership, $nik_customer, $nama_membership, $harga_membership, $potongan, $status);

if ($stmt->execute()) {
    // Master-only: tidak membuat transaksi/jurnal meskipun ada NIK di request
    $koneksi->commit();
    jsonResponse([
        'status' => 'success',
        'message' => 'Membership (master) berhasil ditambahkan',
        'data' => [[
            'ID_MASTER_MEMBERSHIP' => $id_master_membership,
            'NAMA_MEMBERSHIP' => $nama_membership,
            'HARGA_MEMBERSHIP' => $harga_membership,
            'POTONGAN' => $potongan,
            'STATUS' => $status
        ]]
    ]);
    exit;
} else {
    $koneksi->rollback();
    jsonResponse(['status' => 'error', 'message' => $stmt->error]);
    exit;
}

$stmt->close();
$koneksi->close();