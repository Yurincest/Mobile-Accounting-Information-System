<?php
header('Content-Type: application/json; charset=utf-8');
include 'config.php';
include_once '_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonResponse(['status' => 'error', 'message' => 'Invalid request method']);
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

$sql = "SELECT ID_MEMBERSHIP_TYPE, NAMA_MEMBERSHIP, HARGA_MEMBERSHIP, POTONGAN, STATUS FROM MASTER_MEMBERSHIP_TYPE";
$result = $koneksi->query($sql);

$types = [];
if ($result && $result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $row = cleanRow($row);
        $types[] = [
            'ID_MEMBERSHIP_TYPE' => $row['ID_MEMBERSHIP_TYPE'],
            'NAMA_MEMBERSHIP' => $row['NAMA_MEMBERSHIP'],
            'HARGA_MEMBERSHIP' => isset($row['HARGA_MEMBERSHIP']) ? (double)$row['HARGA_MEMBERSHIP'] : 0.0,
            'POTONGAN' => isset($row['POTONGAN']) ? (int)$row['POTONGAN'] : 0,
            'STATUS' => isset($row['STATUS']) ? (int)$row['STATUS'] : 0,
        ];
    }
    jsonResponse(['status' => 'success', 'data' => $types]);
    exit;
} else {
    jsonResponse(['status' => 'error', 'message' => 'Belum ada data']);
    exit;
}

$koneksi->close();
?>