<?php
header('Content-Type: application/json; charset=utf-8');
include 'config.php';
include_once __DIR__ . '/_helper.php';

$start_date = $_GET['start_date'] ?? '';
$end_date = $_GET['end_date'] ?? '';

$where = '';
if (!empty($start_date) && !empty($end_date)) {
    $where = "WHERE ju.TANGGAL BETWEEN ? AND ?";
}

$sql = "SELECT ka.KODE_AKUN, ka.NAMA_AKUN,
        SUM(CASE WHEN jd.POSISI = 'D' THEN jd.NILAI ELSE 0 END) AS TOTAL_DEBIT,
        SUM(CASE WHEN jd.POSISI = 'K' THEN jd.NILAI ELSE 0 END) AS TOTAL_KREDIT,
        SUM(CASE WHEN jd.POSISI = 'D' THEN jd.NILAI ELSE 0 END) - SUM(CASE WHEN jd.POSISI = 'K' THEN jd.NILAI ELSE 0 END) AS SALDO
        FROM KODE_AKUN ka
        LEFT JOIN JURNAL_DETAIL jd ON ka.KODE_AKUN = jd.KODE_AKUN
        LEFT JOIN JURNAL_UMUM ju ON jd.ID_JURNAL_UMUM = ju.ID_JURNAL_UMUM
        $where
        GROUP BY ka.KODE_AKUN, ka.NAMA_AKUN";

if (!empty($where)) {
    $stmt = $koneksi->prepare($sql);
    $stmt->bind_param('ss', $start_date, $end_date);
    $stmt->execute();
    $result = $stmt->get_result();
} else {
    $result = $koneksi->query($sql);
}

if ($result && $result->num_rows > 0) {
    $neraca = [];
    while ($row = $result->fetch_assoc()) {
        $row = cleanRow($row);
        // Sanitasi field teks untuk newline
        $row['NAMA_AKUN'] = isset($row['NAMA_AKUN']) ? str_replace(["\r","\n"], ' ', $row['NAMA_AKUN']) : $row['NAMA_AKUN'];
        $neraca[] = [
            'KODE_AKUN' => $row['KODE_AKUN'],
            'NAMA_AKUN' => $row['NAMA_AKUN'],
            'TOTAL_DEBIT' => (double)$row['TOTAL_DEBIT'],
            'TOTAL_KREDIT' => (double)$row['TOTAL_KREDIT'],
            'SALDO' => (double)$row['SALDO'],
        ];
    }
    $response = ['status' => 'success', 'data' => $neraca];
} else {
    $response = ['status' => 'error', 'message' => 'Belum ada data'];
}

if (isset($stmt)) { $stmt->close(); }
jsonResponse($response);
exit;
$koneksi->close();