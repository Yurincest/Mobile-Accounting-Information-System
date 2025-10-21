<?php
header('Content-Type: application/json; charset=utf-8');
include 'config.php';
include_once '_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(['status' => 'error', 'message' => 'Invalid request method']);
    exit;
}

// Ambil input dari form-data atau JSON body
$data = $_POST;
if (empty($data)) {
    $raw = file_get_contents('php://input');
    $decoded = json_decode($raw, true);
    if (is_array($decoded)) { $data = $decoded; }
}

$id_master = $data['ID_MASTER_MEMBERSHIP'] ?? null;
$nik = $data['NIK_CUSTOMER'] ?? null;
if (!$id_master || !$nik) {
    jsonResponse(['status' => 'error', 'message' => 'ID_MASTER_MEMBERSHIP dan NIK_CUSTOMER wajib']);
    exit;
}

// Cari semua transaksi untuk pasangan master+nik
$stmtTrx = $koneksi->prepare("SELECT ID_TRANSAKSI_MEMBERSHIP FROM TRANSAKSI_MEMBERSHIP WHERE ID_MASTER_MEMBERSHIP = ? AND NIK_CUSTOMER = ?");
if (!$stmtTrx) { jsonResponse(['status' => 'error', 'message' => 'Prepare gagal: ' . $koneksi->error]); exit; }
$stmtTrx->bind_param('ss', $id_master, $nik);
$stmtTrx->execute();
$resTrx = $stmtTrx->get_result();
$trxIds = [];
if ($resTrx) {
    while ($row = $resTrx->fetch_assoc()) {
        if (!empty($row['ID_TRANSAKSI_MEMBERSHIP'])) { $trxIds[] = $row['ID_TRANSAKSI_MEMBERSHIP']; }
    }
}
$stmtTrx->close();

if (empty($trxIds)) {
    jsonResponse(['status' => 'error', 'message' => 'Tidak ada transaksi untuk customer pada master ini']);
    exit;
}

$koneksi->begin_transaction();

// Hapus jurnal untuk tiap transaksi (REF = 'MBR-{ID_TRANSAKSI}')
foreach ($trxIds as $tid) {
    $ref = 'MBR-' . $tid;

    // Ambil ID_JURNAL_UMUM berdasarkan REF
    $stmtJU = $koneksi->prepare("SELECT ID_JURNAL_UMUM FROM JURNAL_UMUM WHERE REF = ?");
    if (!$stmtJU) { $koneksi->rollback(); jsonResponse(['status' => 'error', 'message' => 'Prepare jurnal umum gagal: ' . $koneksi->error]); exit; }
    $stmtJU->bind_param('s', $ref);
    $stmtJU->execute();
    $resJU = $stmtJU->get_result();
    $idJU = null;
    if ($resJU && ($rowJU = $resJU->fetch_assoc())) { $idJU = $rowJU['ID_JURNAL_UMUM'] ?? null; }
    $stmtJU->close();

    if ($idJU) {
        // Hapus detail
        $stmtDelJD = $koneksi->prepare("DELETE FROM JURNAL_DETAIL WHERE ID_JURNAL_UMUM = ?");
        if (!$stmtDelJD) { $koneksi->rollback(); jsonResponse(['status' => 'error', 'message' => 'Prepare delete jurnal detail gagal: ' . $koneksi->error]); exit; }
        $stmtDelJD->bind_param('s', $idJU);
        if (!$stmtDelJD->execute()) { $stmtDelJD->close(); $koneksi->rollback(); jsonResponse(['status' => 'error', 'message' => 'Delete jurnal detail gagal: ' . $stmtDelJD->error]); exit; }
        $stmtDelJD->close();

        // Hapus umum
        $stmtDelJU = $koneksi->prepare("DELETE FROM JURNAL_UMUM WHERE ID_JURNAL_UMUM = ?");
        if (!$stmtDelJU) { $koneksi->rollback(); jsonResponse(['status' => 'error', 'message' => 'Prepare delete jurnal umum gagal: ' . $koneksi->error]); exit; }
        $stmtDelJU->bind_param('s', $idJU);
        if (!$stmtDelJU->execute()) { $stmtDelJU->close(); $koneksi->rollback(); jsonResponse(['status' => 'error', 'message' => 'Delete jurnal umum gagal: ' . $stmtDelJU->error]); exit; }
        $stmtDelJU->close();
    }
}

// Hapus semua transaksi membership untuk pasangan master+nik
$stmtDelTrx = $koneksi->prepare("DELETE FROM TRANSAKSI_MEMBERSHIP WHERE ID_MASTER_MEMBERSHIP = ? AND NIK_CUSTOMER = ?");
if (!$stmtDelTrx) { $koneksi->rollback(); jsonResponse(['status' => 'error', 'message' => 'Prepare delete transaksi gagal: ' . $koneksi->error]); exit; }
$stmtDelTrx->bind_param('ss', $id_master, $nik);
if (!$stmtDelTrx->execute()) { $stmtDelTrx->close(); $koneksi->rollback(); jsonResponse(['status' => 'error', 'message' => 'Delete transaksi gagal: ' . $stmtDelTrx->error]); exit; }
$stmtDelTrx->close();

$koneksi->commit();
jsonResponse(['status' => 'success', 'message' => 'Customer dihapus dari membership', 'data' => [[
    'ID_MASTER_MEMBERSHIP' => $id_master,
    'NIK_CUSTOMER' => $nik
]]]);
$koneksi->close();
?>