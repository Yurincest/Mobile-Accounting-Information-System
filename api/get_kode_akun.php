<?php
header('Content-Type: application/json; charset=utf-8');
include 'config.php';
include_once '_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonResponse(['status' => 'error', 'message' => 'Invalid request method']);
    exit;
}

$sql = "SELECT * FROM KODE_AKUN";
$result = $koneksi->query($sql);

$akuns = [];
if ($result && $result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $akuns[] = cleanRow($row);
    }
    jsonResponse(['status' => 'success', 'data' => $akuns]);
    exit;
} else {
    jsonResponse(['status' => 'error', 'message' => 'Belum ada data']);
    exit;
}

$koneksi->close();