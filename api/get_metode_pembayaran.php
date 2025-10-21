<?php
header('Content-Type: application/json; charset=utf-8');
include 'config.php';
include_once '_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonResponse(['status' => 'error', 'message' => 'Invalid request method']);
    exit;
}

$sql = "SELECT ID_MPEM, NAMA_MPEM, STATUS FROM MSTR_METODE_PEMBAYARAN";
$result = $koneksi->query($sql);

$metode = [];
if ($result && $result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $row = cleanRow($row);
        // Alias kolom ke schema JSON lama agar Flutter tetap kompatibel
        $metode[] = [
            'KODE_METODE' => $row['ID_MPEM'],
            'NAMA_METODE' => $row['NAMA_MPEM'],
            'STATUS' => isset($row['STATUS']) ? (int)$row['STATUS'] : 1,
        ];
    }
    jsonResponse(['status' => 'success', 'data' => $metode]);
    exit;
} else {
    jsonResponse(['status' => 'error', 'message' => 'Belum ada data']);
    exit;
}

$koneksi->close();