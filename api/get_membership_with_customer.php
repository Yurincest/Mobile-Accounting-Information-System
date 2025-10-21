<?php
header('Content-Type: application/json; charset=utf-8');
include 'config.php';
include_once '_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonResponse(['status' => 'error', 'message' => 'Invalid request method']);
    exit;
}

// Struktur baru: kembalikan array CUSTOMERS terstruktur per master membership.
// CUSTOMER adalah transaksi terbaru per NIK pada master tersebut (aktif atau nonaktif),
// menyertakan info sisa hari dan flag aktif berdasarkan TIMESTAMP_HABIS.
$sqlMasters = "SELECT ID_MASTER_MEMBERSHIP, NAMA_MEMBERSHIP, HARGA_MEMBERSHIP, POTONGAN, STATUS FROM MASTER_MEMBERSHIP ORDER BY NAMA_MEMBERSHIP";
$resMasters = $koneksi->query($sqlMasters);

if ($resMasters) {
    $memberships = [];
    while ($mm = $resMasters->fetch_assoc()) {
        $mm = cleanRow($mm);

        // Ambil transaksi terbaru per customer untuk master ini
        $sqlCustomers = "SELECT tm.ID_TRANSAKSI_MEMBERSHIP, tm.ID_MASTER_MEMBERSHIP, tm.NIK_CUSTOMER, tm.NAMA_MEMBERSHIP,
                                tm.HARGA_MEMBERSHIP, tm.POTONGAN, tm.TIMESTAMP_HABIS,
                                COALESCE(c.NAMA_CUSTOMER, tm.NIK_CUSTOMER) AS NAMA_CUSTOMER,
                                CASE WHEN tm.TIMESTAMP_HABIS > NOW() THEN 1 ELSE 0 END AS STATUS,
                                DATEDIFF(tm.TIMESTAMP_HABIS, NOW()) AS SISA_HARI
                         FROM TRANSAKSI_MEMBERSHIP tm
                         JOIN (
                           SELECT ID_MASTER_MEMBERSHIP, NIK_CUSTOMER, MAX(TIMESTAMP_HABIS) AS MAX_TS
                           FROM TRANSAKSI_MEMBERSHIP
                           WHERE ID_MASTER_MEMBERSHIP = ?
                           GROUP BY ID_MASTER_MEMBERSHIP, NIK_CUSTOMER
                         ) latest ON latest.ID_MASTER_MEMBERSHIP = tm.ID_MASTER_MEMBERSHIP
                                  AND latest.NIK_CUSTOMER = tm.NIK_CUSTOMER
                                  AND latest.MAX_TS = tm.TIMESTAMP_HABIS
                         LEFT JOIN CUSTOMER c ON c.NIK_CUSTOMER = tm.NIK_CUSTOMER
                         ORDER BY STATUS DESC, NAMA_CUSTOMER";
        $stmtC = $koneksi->prepare($sqlCustomers);
        $stmtC->bind_param('s', $mm['ID_MASTER_MEMBERSHIP']);
        $stmtC->execute();
        $resC = $stmtC->get_result();
        $customers = [];
        $hasActive = 0;
        $maxSisaHari = null;
        $latestActiveTs = null;
        if ($resC && $resC->num_rows > 0) {
            while ($row = $resC->fetch_assoc()) {
                $row = cleanRow($row);
                $customers[] = [
                    'ID_TRANSAKSI_MEMBERSHIP' => $row['ID_TRANSAKSI_MEMBERSHIP'],
                    'NIK_CUSTOMER' => $row['NIK_CUSTOMER'],
                    'NAMA_CUSTOMER' => $row['NAMA_CUSTOMER'],
                    'TIMESTAMP_HABIS' => $row['TIMESTAMP_HABIS'],
                    'SISA_HARI' => $row['SISA_HARI'],
                    'STATUS' => (int)$row['STATUS'],
                ];
                if ((int)$row['STATUS'] === 1) {
                    $hasActive = 1;
                    $diff = isset($row['SISA_HARI']) ? (int)$row['SISA_HARI'] : null;
                    if ($diff !== null && ($maxSisaHari === null || $diff > $maxSisaHari)) {
                        $maxSisaHari = $diff;
                        $latestActiveTs = $row['TIMESTAMP_HABIS'];
                    }
                }
            }
        }
        $stmtC->close();

        $memberships[] = [
            'ID_MASTER_MEMBERSHIP' => $mm['ID_MASTER_MEMBERSHIP'],
            'NAMA_MEMBERSHIP' => $mm['NAMA_MEMBERSHIP'],
            'HARGA_MEMBERSHIP' => isset($mm['HARGA_MEMBERSHIP']) ? (double)$mm['HARGA_MEMBERSHIP'] : 0.0,
            'POTONGAN' => isset($mm['POTONGAN']) ? (int)$mm['POTONGAN'] : 0,
            'STATUS' => isset($mm['STATUS']) ? (int)$mm['STATUS'] : 0,
            'HAS_ACTIVE_MEMBERSHIP' => $hasActive,
            'SISA_HARI' => $maxSisaHari,
            'TIMESTAMP_HABIS' => $latestActiveTs,
            'CUSTOMERS' => $customers,
        ];
    }
    jsonResponse(['status' => 'success', 'data' => $memberships]);
} else {
    jsonResponse(['status' => 'error', 'message' => 'Gagal mengambil data membership: ' . $koneksi->error]);
}

$koneksi->close();
?>