<?php
header('Content-Type: application/json; charset=utf-8');
include 'config.php';
include_once '_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonResponse(['status' => 'error', 'message' => 'Invalid request method']);
    exit;
}

// NIK_CUSTOMER opsional: jika diberikan, hanya master yang memiliki NIK tersebut yang dikembalikan
$nik_filter = $_GET['NIK_CUSTOMER'] ?? null;

// Ambil master yang memiliki transaksi aktif
$memberships = [];
if ($nik_filter) {
    $sqlM = "SELECT mm.ID_MASTER_MEMBERSHIP, mm.NAMA_MEMBERSHIP, mm.HARGA_MEMBERSHIP, mm.POTONGAN, mm.STATUS
             FROM MASTER_MEMBERSHIP mm
             WHERE EXISTS (
               SELECT 1 FROM TRANSAKSI_MEMBERSHIP tm
               WHERE tm.ID_MASTER_MEMBERSHIP = mm.ID_MASTER_MEMBERSHIP
                 AND tm.TIMESTAMP_HABIS > NOW()
                 AND tm.NIK_CUSTOMER = ?
             )";
    $stmtM = $koneksi->prepare($sqlM);
    $stmtM->bind_param('s', $nik_filter);
} else {
    $sqlM = "SELECT mm.ID_MASTER_MEMBERSHIP, mm.NAMA_MEMBERSHIP, mm.HARGA_MEMBERSHIP, mm.POTONGAN, mm.STATUS
             FROM MASTER_MEMBERSHIP mm
             WHERE EXISTS (
               SELECT 1 FROM TRANSAKSI_MEMBERSHIP tm
               WHERE tm.ID_MASTER_MEMBERSHIP = mm.ID_MASTER_MEMBERSHIP
                 AND tm.TIMESTAMP_HABIS > NOW()
             )";
    $stmtM = $koneksi->prepare($sqlM);
}

$stmtM->execute();
$resM = $stmtM->get_result();
if ($resM && $resM->num_rows > 0) {
    while ($row = $resM->fetch_assoc()) {
        $row = cleanRow($row);
        $id_master = $row['ID_MASTER_MEMBERSHIP'];

        // Tarik anggota aktif untuk master ini, optional filter NIK
        if ($nik_filter) {
            $sqlMem = "SELECT NIK_CUSTOMER, TIMESTAMP_HABIS
                       FROM TRANSAKSI_MEMBERSHIP
                       WHERE ID_MASTER_MEMBERSHIP = ? AND TIMESTAMP_HABIS > NOW() AND NIK_CUSTOMER = ?
                       ORDER BY TIMESTAMP_HABIS DESC";
            $stmtMem = $koneksi->prepare($sqlMem);
            $stmtMem->bind_param('ss', $id_master, $nik_filter);
        } else {
            $sqlMem = "SELECT NIK_CUSTOMER, TIMESTAMP_HABIS
                       FROM TRANSAKSI_MEMBERSHIP
                       WHERE ID_MASTER_MEMBERSHIP = ? AND TIMESTAMP_HABIS > NOW()
                       ORDER BY TIMESTAMP_HABIS DESC";
            $stmtMem = $koneksi->prepare($sqlMem);
            $stmtMem->bind_param('s', $id_master);
        }
        $stmtMem->execute();
        $resMem = $stmtMem->get_result();
        $members = [];
        if ($resMem && $resMem->num_rows > 0) {
            while ($m = $resMem->fetch_assoc()) {
                $m = cleanRow($m);
                $members[] = [
                    'NIK_CUSTOMER' => $m['NIK_CUSTOMER'] ?? null,
                    'TIMESTAMP_HABIS' => $m['TIMESTAMP_HABIS'] ?? null,
                    // Anggota yang dikembalikan pasti aktif (berdasarkan TIMESTAMP_HABIS)
                    'STATUS' => 1,
                ];
            }
        }
        $stmtMem->close();

        $memberships[] = [
            'ID_MASTER_MEMBERSHIP' => $id_master,
            'NAMA_MEMBERSHIP' => $row['NAMA_MEMBERSHIP'],
            'HARGA_MEMBERSHIP' => isset($row['HARGA_MEMBERSHIP']) ? (double)$row['HARGA_MEMBERSHIP'] : 0.0,
            'POTONGAN' => isset($row['POTONGAN']) ? (int)$row['POTONGAN'] : 0,
            'STATUS' => isset($row['STATUS']) ? (int)$row['STATUS'] : 0,
            'members' => $members,
        ];
    }
    jsonResponse(['status' => 'success', 'data' => $memberships]);
    exit;
} else {
    jsonResponse(['status' => 'error', 'message' => 'Belum ada membership aktif']);
    exit;
}

$stmtM->close();
$koneksi->close();