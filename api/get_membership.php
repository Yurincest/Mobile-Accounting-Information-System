<?php
header('Content-Type: application/json; charset=utf-8');
include 'config.php';
include_once '_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonResponse(['status' => 'error', 'message' => 'Invalid request method']);
}

$sql = "SELECT ID_MASTER_MEMBERSHIP, NAMA_MEMBERSHIP, HARGA_MEMBERSHIP, POTONGAN, STATUS FROM MASTER_MEMBERSHIP";
$result = $koneksi->query($sql);

$memberships = [];
if ($result && $result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $row = cleanRow($row);
        $id_master = $row['ID_MASTER_MEMBERSHIP'];

        // Ambil anggota aktif untuk master ini (belum habis masa berlaku)
        $sqlMem = "SELECT NIK_CUSTOMER, TIMESTAMP_HABIS FROM TRANSAKSI_MEMBERSHIP WHERE ID_MASTER_MEMBERSHIP = ? AND TIMESTAMP_HABIS > NOW() ORDER BY TIMESTAMP_HABIS DESC";
        $stmtMem = $koneksi->prepare($sqlMem);
        $stmtMem->bind_param('s', $id_master);
        $stmtMem->execute();
        $resMem = $stmtMem->get_result();
        $members = [];
        if ($resMem && $resMem->num_rows > 0) {
            while ($m = $resMem->fetch_assoc()) {
                $m = cleanRow($m);
                $members[] = [
                    'NIK_CUSTOMER' => $m['NIK_CUSTOMER'] ?? null,
                    'TIMESTAMP_HABIS' => $m['TIMESTAMP_HABIS'] ?? null,
                    // Kembalikan STATUS=1 untuk anggota yang masih aktif (berdasarkan TIMESTAMP_HABIS)
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
            // Struktur grouping: daftar anggota aktif di bawah master
            'members' => $members,
        ];
    }
    jsonResponse(['status' => 'success', 'data' => $memberships]);
    exit;
} else {
    jsonResponse(['status' => 'error', 'message' => 'Belum ada data']);
    exit;
}

$koneksi->close();