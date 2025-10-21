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

$status = $data['STATUS'] ?? null;
$id_trx = $data['ID_TRANSAKSI_MEMBERSHIP'] ?? null;
$id_master = $data['ID_MASTER_MEMBERSHIP'] ?? null;
$nik = $data['NIK_CUSTOMER'] ?? null;

if ($status === null) {
    jsonResponse(['status' => 'error', 'message' => 'STATUS wajib']);
    exit;
}
$status = (int)$status;

if ($id_trx) {
    // Toggle berdasarkan ID transaksi langsung
    $sql = "UPDATE TRANSAKSI_MEMBERSHIP SET STATUS = ? WHERE ID_TRANSAKSI_MEMBERSHIP = ?";
    $stmt = $koneksi->prepare($sql);
    if (!$stmt) { jsonResponse(['status' => 'error', 'message' => 'Prepare gagal: ' . $koneksi->error]); exit; }
    $stmt->bind_param('is', $status, $id_trx);
} else {
    // Toggle berdasarkan pasangan master + NIK (gunakan transaksi terbaru)
    if ($id_master === null || $nik === null) {
        jsonResponse(['status' => 'error', 'message' => 'ID_TRANSAKSI_MEMBERSHIP atau (ID_MASTER_MEMBERSHIP + NIK_CUSTOMER) wajib']);
        exit;
    }
    // Ambil transaksi terbaru untuk pasangan ini
    $sqlGet = "SELECT ID_TRANSAKSI_MEMBERSHIP FROM TRANSAKSI_MEMBERSHIP WHERE ID_MASTER_MEMBERSHIP = ? AND NIK_CUSTOMER = ? ORDER BY TIMESTAMP_HABIS DESC LIMIT 1";
    $stmtG = $koneksi->prepare($sqlGet);
    $stmtG->bind_param('ss', $id_master, $nik);
    $stmtG->execute();
    $resG = $stmtG->get_result();
    $id_found = null;
    if ($resG && ($row = $resG->fetch_assoc())) { $id_found = $row['ID_TRANSAKSI_MEMBERSHIP'] ?? null; }
    $stmtG->close();
    if (!$id_found) { jsonResponse(['status' => 'error', 'message' => 'Transaksi membership tidak ditemukan untuk customer']); exit; }

    // Skema tidak memiliki kolom STATUS; gunakan TIMESTAMP_HABIS sebagai kontrol aktif/nonaktif
    if ($status === 0) {
        // Nonaktifkan segera dengan mengatur masa berlaku habis sekarang
        $sql = "UPDATE TRANSAKSI_MEMBERSHIP SET TIMESTAMP_HABIS = NOW() WHERE ID_TRANSAKSI_MEMBERSHIP = ?";
        $stmt = $koneksi->prepare($sql);
        if (!$stmt) { jsonResponse(['status' => 'error', 'message' => 'Prepare gagal: ' . $koneksi->error]); exit; }
        $stmt->bind_param('s', $id_found);
    } else {
        // Aktifkan/perpanjang: set masa berlaku 60 hari dari sekarang
        $sql = "UPDATE TRANSAKSI_MEMBERSHIP SET TIMESTAMP_HABIS = DATE_ADD(NOW(), INTERVAL 60 DAY) WHERE ID_TRANSAKSI_MEMBERSHIP = ?";
        $stmt = $koneksi->prepare($sql);
        if (!$stmt) { jsonResponse(['status' => 'error', 'message' => 'Prepare gagal: ' . $koneksi->error]); exit; }
        $stmt->bind_param('s', $id_found);
    }
}

if ($stmt->execute()) {
    jsonResponse(['status' => 'success', 'message' => 'Status membership customer diperbarui']);
    exit;
} else {
    jsonResponse(['status' => 'error', 'message' => $stmt->error]);
    exit;
}

$stmt->close();
$koneksi->close();

?>