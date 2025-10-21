<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

include 'config.php';
include_once '_helper.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Ambil input dari form-data atau JSON
    $data = $_POST;
    if (empty($data)) {
        $raw = file_get_contents('php://input');
        $data = json_decode($raw, true) ?? [];
    }

    $email = trim($data['email'] ?? '');
    $password = trim($data['password'] ?? '');

    if ($email === '' || $password === '') {
        jsonResponse(['status' => 'error', 'message' => 'Email dan password harus diisi']);
        exit;
    }

    // Gunakan prepared statement MySQLi (bukan PDO)
    $sql = "SELECT NIK_KARYAWAN, NAMA_KARYAWAN, EMAIL FROM KARYAWAN WHERE EMAIL = ? AND PASSWORD = ?";
    $stmt = $koneksi->prepare($sql);
    if (!$stmt) {
        jsonResponse(['status' => 'error', 'message' => 'Query prepare gagal: ' . $koneksi->error]);
        exit;
    }

    $stmt->bind_param('ss', $email, $password);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result && ($user = $result->fetch_assoc())) {
        $user = cleanRow($user);
        jsonResponse(['status' => 'success', 'user' => $user]);
        exit;
    } else {
        jsonResponse(['status' => 'error', 'message' => 'Invalid credentials']);
        exit;
    }

    $stmt->close();
    $koneksi->close();
} else {
    jsonResponse(['status' => 'error', 'message' => 'Metode request tidak valid']);
    exit;
}
