<?php
header('Content-Type: application/json; charset=utf-8');
include 'config.php';
include_once '_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonResponse(['status' => 'error', 'message' => 'Invalid request method']);
    exit;
}

$sql = "SELECT * FROM KARYAWAN";
$result = $koneksi->query($sql);

$karyawan = [];
if ($result && $result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $karyawan[] = cleanRow($row);
    }
    jsonResponse(['status' => 'success', 'data' => $karyawan]);
    exit;
} else {
    jsonResponse(['status' => 'error', 'message' => 'Belum ada data']);
    exit;
}

$koneksi->close();