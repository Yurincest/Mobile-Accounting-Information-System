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
    $raw = file_get_contents('php://input');
    $decoded = json_decode($raw, true);
    if (is_array($decoded)) { $data = $decoded; }
}

$id_master = $data['ID_MASTER_MEMBERSHIP'] ?? null;
$status = $data['STATUS'] ?? null;
if ($id_master === null || $status === null) {
    jsonResponse(['status' => 'error', 'message' => 'ID_MASTER_MEMBERSHIP dan STATUS wajib']);
    exit;
}
$status = (int)$status;

$sql = "UPDATE MASTER_MEMBERSHIP SET STATUS = ?, LAST_UPDATED = NOW() WHERE ID_MASTER_MEMBERSHIP = ?";
$stmt = $koneksi->prepare($sql);
if (!$stmt) { jsonResponse(['status' => 'error', 'message' => 'Prepare gagal: ' . $koneksi->error]); exit; }
$stmt->bind_param('is', $status, $id_master);

if ($stmt->execute()) {
    jsonResponse(['status' => 'success', 'message' => 'Status membership master diperbarui']);
    exit;
} else {
    jsonResponse(['status' => 'error', 'message' => $stmt->error]);
    exit;
}

$stmt->close();
$koneksi->close();

?>