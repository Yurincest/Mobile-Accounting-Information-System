<?php
header('Content-Type: application/json');
include 'config.php';
include_once '_helper.php';

$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['KODE_METODE']) || !isset($data['NAMA_METODE']) || !isset($data['STATUS'])) {
    jsonResponse(['status' => 'error', 'message' => 'All fields are required']);
    exit;
}

$kode = $data['KODE_METODE'];
$nama = $data['NAMA_METODE'];
$status = (int)$data['STATUS'];

$sql = "UPDATE MSTR_METODE_PEMBAYARAN SET NAMA_MPEM = ?, STATUS = ? WHERE ID_MPEM = ?";
$stmt = $koneksi->prepare($sql);
$stmt->bind_param("sis", $nama, $status, $kode);

if ($stmt->execute()) {
    jsonResponse(['status' => 'success', 'message' => 'Metode Pembayaran updated successfully', 'data' => [[
        'KODE_METODE' => $kode,
        'NAMA_METODE' => $nama,
        'STATUS' => $status,
    ]]]);
    exit;
} else {
    jsonResponse(['status' => 'error', 'message' => $stmt->error]);
    exit;
}

$stmt->close();
$koneksi->close();