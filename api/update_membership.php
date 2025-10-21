<?php
header('Content-Type: application/json; charset=utf-8');
include 'config.php';
include_once '_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(['status' => 'error', 'message' => 'Invalid request method']);
    exit;
}

$data = json_decode(file_get_contents("php://input"), true);

// Master-only: tidak perlu NIK karyawan maupun NIK customer
if (!isset($data['ID_MASTER_MEMBERSHIP']) || !isset($data['NAMA_MEMBERSHIP']) || !isset($data['HARGA_MEMBERSHIP']) || !isset($data['POTONGAN']) || !isset($data['STATUS'])) {
    jsonResponse(['status' => 'error', 'message' => 'Fields ID_MASTER_MEMBERSHIP, NAMA_MEMBERSHIP, HARGA_MEMBERSHIP, POTONGAN, STATUS wajib']);
    exit;
}

$id_master_membership = $data['ID_MASTER_MEMBERSHIP'];
$nama_membership = $data['NAMA_MEMBERSHIP'];
$harga_membership = (double)$data['HARGA_MEMBERSHIP'];
$potongan = (int)$data['POTONGAN'];
$status = (int)$data['STATUS'];

$sql = "UPDATE MASTER_MEMBERSHIP SET NAMA_MEMBERSHIP = ?, HARGA_MEMBERSHIP = ?, POTONGAN = ?, STATUS = ? WHERE ID_MASTER_MEMBERSHIP = ?";
$stmt = $koneksi->prepare($sql);
$stmt->bind_param("sdiis", $nama_membership, $harga_membership, $potongan, $status, $id_master_membership);

if ($stmt->execute()) {
    jsonResponse(['status' => 'success', 'message' => 'Membership berhasil diperbarui', 'data' => [[
        'ID_MASTER_MEMBERSHIP' => $id_master_membership
    ]]]);
    exit;
} else {
    jsonResponse(['status' => 'error', 'message' => $stmt->error]);
    exit;
}

$stmt->close();
$koneksi->close();