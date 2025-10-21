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
    $data = json_decode(file_get_contents('php://input'), true) ?? [];
}

if (!isset($data['ID_MASTER_MEMBERSHIP'])) {
    jsonResponse(['status' => 'error', 'message' => 'ID_MASTER_MEMBERSHIP is required']);
    exit;
}

$id_master_membership = $data['ID_MASTER_MEMBERSHIP'];

$koneksi->begin_transaction();

// Ambil semua transaksi terkait master ini
$sqlTrx = "SELECT ID_TRANSAKSI_MEMBERSHIP FROM TRANSAKSI_MEMBERSHIP WHERE ID_MASTER_MEMBERSHIP = ?";
$stmtTrx = $koneksi->prepare($sqlTrx);
if (!$stmtTrx) { $koneksi->rollback(); jsonResponse(['status' => 'error', 'message' => 'Prepare gagal: ' . $koneksi->error]); exit; }
$stmtTrx->bind_param("s", $id_master_membership);
$stmtTrx->execute();
$resTrx = $stmtTrx->get_result();
$trxIds = [];
if ($resTrx) {
    while ($row = $resTrx->fetch_assoc()) {
        if (!empty($row['ID_TRANSAKSI_MEMBERSHIP'])) { $trxIds[] = $row['ID_TRANSAKSI_MEMBERSHIP']; }
    }
}
$stmtTrx->close();

// Hapus jurnal detail dan jurnal umum untuk setiap transaksi (REF = 'MBR-{ID_TRANSAKSI}')
foreach ($trxIds as $tid) {
    $ref = 'MBR-' . $tid;
    // Ambil ID_JURNAL_UMUM berdasarkan REF
    $stmtJU = $koneksi->prepare("SELECT ID_JURNAL_UMUM FROM JURNAL_UMUM WHERE REF = ?");
    if (!$stmtJU) { $koneksi->rollback(); jsonResponse(['status' => 'error', 'message' => 'Prepare jurnal umum gagal: ' . $koneksi->error]); exit; }
    $stmtJU->bind_param("s", $ref);
    $stmtJU->execute();
    $resJU = $stmtJU->get_result();
    $idJUs = [];
    if ($resJU) {
        while ($r = $resJU->fetch_assoc()) { if (!empty($r['ID_JURNAL_UMUM'])) { $idJUs[] = $r['ID_JURNAL_UMUM']; } }
    }
    $stmtJU->close();

    // Hapus JURNAL_DETAIL untuk semua ID_JURNAL_UMUM yang ditemukan
    foreach ($idJUs as $jid) {
        $stmtDelJD = $koneksi->prepare("DELETE FROM JURNAL_DETAIL WHERE ID_JURNAL_UMUM = ?");
        if (!$stmtDelJD) { $koneksi->rollback(); jsonResponse(['status' => 'error', 'message' => 'Prepare delete jurnal detail gagal: ' . $koneksi->error]); exit; }
        $stmtDelJD->bind_param("s", $jid);
        if (!$stmtDelJD->execute()) { $stmtDelJD->close(); $koneksi->rollback(); jsonResponse(['status' => 'error', 'message' => 'Delete jurnal detail gagal: ' . $stmtDelJD->error]); exit; }
        $stmtDelJD->close();
    }

    // Hapus JURNAL_UMUM berdasarkan REF
    $stmtDelJU = $koneksi->prepare("DELETE FROM JURNAL_UMUM WHERE REF = ?");
    if (!$stmtDelJU) { $koneksi->rollback(); jsonResponse(['status' => 'error', 'message' => 'Prepare delete jurnal umum gagal: ' . $koneksi->error]); exit; }
    $stmtDelJU->bind_param("s", $ref);
    if (!$stmtDelJU->execute()) { $stmtDelJU->close(); $koneksi->rollback(); jsonResponse(['status' => 'error', 'message' => 'Delete jurnal umum gagal: ' . $stmtDelJU->error]); exit; }
    $stmtDelJU->close();
}

// Hapus transaksi membership terkait master
$stmtDelTrx = $koneksi->prepare("DELETE FROM TRANSAKSI_MEMBERSHIP WHERE ID_MASTER_MEMBERSHIP = ?");
if (!$stmtDelTrx) { $koneksi->rollback(); jsonResponse(['status' => 'error', 'message' => 'Prepare delete transaksi gagal: ' . $koneksi->error]); exit; }
$stmtDelTrx->bind_param("s", $id_master_membership);
if (!$stmtDelTrx->execute()) { $stmtDelTrx->close(); $koneksi->rollback(); jsonResponse(['status' => 'error', 'message' => 'Delete transaksi gagal: ' . $stmtDelTrx->error]); exit; }
$stmtDelTrx->close();

// Terakhir, hapus master membership
$stmtDelMaster = $koneksi->prepare("DELETE FROM MASTER_MEMBERSHIP WHERE ID_MASTER_MEMBERSHIP = ?");
if (!$stmtDelMaster) { $koneksi->rollback(); jsonResponse(['status' => 'error', 'message' => 'Prepare delete master gagal: ' . $koneksi->error]); exit; }
$stmtDelMaster->bind_param("s", $id_master_membership);
if (!$stmtDelMaster->execute()) { $stmtDelMaster->close(); $koneksi->rollback(); jsonResponse(['status' => 'error', 'message' => 'Delete master gagal: ' . $stmtDelMaster->error]); exit; }
$stmtDelMaster->close();

$koneksi->commit();
jsonResponse(['status' => 'success', 'message' => 'Membership dan transaksi terkait sudah dihapus', 'data' => [[
    'ID_MASTER_MEMBERSHIP' => $id_master_membership
]]]);
$koneksi->close();