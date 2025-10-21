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

if (!isset($data['ID_MEMBERSHIP_TYPE']) || !isset($data['NAMA_MEMBERSHIP']) || !isset($data['HARGA_MEMBERSHIP']) || !isset($data['POTONGAN']) || !isset($data['STATUS'])) {
    jsonResponse(['status' => 'error', 'message' => 'All fields are required']);
    exit;
}

$sqlCreate = "CREATE TABLE IF NOT EXISTS MASTER_MEMBERSHIP_TYPE (
  ID_MEMBERSHIP_TYPE varchar(10) NOT NULL,
  NAMA_MEMBERSHIP varchar(50) NOT NULL,
  HARGA_MEMBERSHIP decimal(25,0) NOT NULL,
  POTONGAN decimal(2,0) NOT NULL,
  STATUS decimal(1,0) NOT NULL,
  LAST_UPDATED timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ID_MEMBERSHIP_TYPE)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci";
$koneksi->query($sqlCreate);

$id = $data['ID_MEMBERSHIP_TYPE'];
$nama = $data['NAMA_MEMBERSHIP'];
$harga = (double)$data['HARGA_MEMBERSHIP'];
$potongan = (int)$data['POTONGAN'];
$status = (int)$data['STATUS'];

$sql = "UPDATE MASTER_MEMBERSHIP_TYPE SET NAMA_MEMBERSHIP = ?, HARGA_MEMBERSHIP = ?, POTONGAN = ?, STATUS = ?, LAST_UPDATED = NOW() WHERE ID_MEMBERSHIP_TYPE = ?";
$stmt = $koneksi->prepare($sql);
$stmt->bind_param("sdiss", $nama, $harga, $potongan, $status, $id);

if ($stmt->execute()) {
    jsonResponse(['status' => 'success', 'message' => 'Membership type diperbarui']);
    exit;
} else {
    jsonResponse(['status' => 'error', 'message' => $stmt->error]);
    exit;
}

$stmt->close();
$koneksi->close();
?>