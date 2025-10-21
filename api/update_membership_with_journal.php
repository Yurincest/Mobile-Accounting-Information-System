<?php
// Endpoint ini dibuat deprecated untuk meminimalkan rombakan dan mencegah duplikasi logika jurnal.
header('Content-Type: application/json; charset=utf-8');
include 'config.php';
include_once '_helper.php';

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(['status' => 'error', 'message' => 'Invalid request method']);
}

jsonResponse([
    'status' => 'error',
    'message' => 'Endpoint deprecated. Gunakan add_member_to_membership.php untuk penugasan/jurnal dan update_membership.php untuk edit master.'
]);
?>