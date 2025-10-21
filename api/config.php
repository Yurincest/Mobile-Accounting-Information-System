<?php
// Debug settings
error_reporting(E_ALL);
ini_set('display_errors', '0'); // Matikan output error agar tidak merusak JSON

// Tambahan: CORS dan no-cache untuk semua endpoint API
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Credentials: true');
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
header('Pragma: no-cache');
header('Expires: 0');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Sertakan helper global untuk respons JSON dan sanitasi
include_once __DIR__ . '/_helper.php';

// Konfigurasi koneksi database
$host = 'localhost';
$user = 'sooa7192_Aldo';
$pass = 'R4h4siaa1234';
$db = 'sooa7192_SIA'; // Live: case-sensitive di Linux

// Membuat koneksi MySQLi
$koneksi = new mysqli($host, $user, $pass, $db);

// Periksa koneksi
if ($koneksi->connect_error) {
    jsonResponse([
        'status' => 'error',
        'message' => 'Koneksi database gagal: ' . $koneksi->connect_error
    ]);
}

// Set charset UTF-8 (utf8mb4 untuk dukungan penuh karakter Unicode)
$koneksi->set_charset('utf8mb4');