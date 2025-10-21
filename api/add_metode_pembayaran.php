<?php
header('Content-Type: application/json; charset=utf-8');
include 'config.php';
include_once '_helper.php';
include 'generate_code.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(['status' => 'error', 'message' => 'Invalid request method']);
    exit;
}

$data = $_POST;
if (empty($data)) {
    $data = json_decode(file_get_contents('php://input'), true) ?? [];
}

if (!isset($data['NAMA_METODE']) || !isset($data['STATUS'])) {
    jsonResponse(['status' => 'error', 'message' => 'NAMA_METODE dan STATUS wajib diisi']);
    exit;
}

$kode = $data['KODE_METODE'] ?? '';
$nama = $data['NAMA_METODE'];
$status = (int)$data['STATUS'];

// Map ke kolom baru
$id_mpem = !empty($kode) ? $kode : generateCode('MPM');
$nama_mpem = $nama;

$sql = "INSERT INTO MSTR_METODE_PEMBAYARAN (ID_MPEM, NAMA_MPEM, STATUS) VALUES (?, ?, ?)";
$stmt = $koneksi->prepare($sql);
$stmt->bind_param("ssi", $id_mpem, $nama_mpem, $status);

if ($stmt->execute()) {
    jsonResponse(['status' => 'success', 'message' => 'Metode Pembayaran berhasil ditambahkan', 'data' => [[
        'KODE_METODE' => $id_mpem,
        'NAMA_METODE' => $nama_mpem,
        'STATUS' => $status,
    ]]]);
    exit;
} else {
    jsonResponse(['status' => 'error', 'message' => 'Database query gagal']);
    exit;
}

$stmt->close();
$koneksi->close();