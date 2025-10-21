<?php
header('Content-Type: application/json; charset=utf-8');
include 'config.php';
include_once __DIR__ . '/_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonResponse(['status' => 'error', 'message' => 'Invalid request method']);
    exit;
}

$kode_akun = $_GET['KODE_AKUN'] ?? '';
$start_date = $_GET['start_date'] ?? '';
$end_date = $_GET['end_date'] ?? '';

if (empty($kode_akun)) {
    jsonResponse(['status' => 'error', 'message' => 'Kode akun diperlukan']);
    exit;
}

$sql = "SELECT jd.ID_JURNAL_UMUM, jd.KODE_AKUN, jd.POSISI, jd.NILAI, ju.TANGGAL, ju.KETERANGAN 
        FROM JURNAL_DETAIL jd 
        JOIN JURNAL_UMUM ju ON jd.ID_JURNAL_UMUM = ju.ID_JURNAL_UMUM 
        WHERE jd.KODE_AKUN = ?";
$types = "i";
$params = [$kode_akun];

if (!empty($start_date) && !empty($end_date)) {
    $sql .= " AND ju.TANGGAL BETWEEN ? AND ?";
    $types .= "ss";
    $params[] = $start_date;
    $params[] = $end_date;
}

$sql .= " ORDER BY ju.TANGGAL";

$stmt = $koneksi->prepare($sql);
$stmt->bind_param($types, ...$params);
$stmt->execute();
$result = $stmt->get_result();

$entries = [];
if ($result && $result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $row = cleanRow($row);
        // Sanitasi newline pada field teks
        if (isset($row['KETERANGAN'])) {
            $row['KETERANGAN'] = str_replace(["\r","\n"], ' ', $row['KETERANGAN']);
        }
        $entries[] = [
            'TANGGAL' => $row['TANGGAL'] ?? null,
            'KETERANGAN' => $row['KETERANGAN'] ?? null,
            'DEBIT' => (isset($row['POSISI']) && $row['POSISI'] === 'D') ? (double)$row['NILAI'] : 0.0,
            'KREDIT' => (isset($row['POSISI']) && $row['POSISI'] === 'K') ? (double)$row['NILAI'] : 0.0,
        ];
    }
    $response = ['status' => 'success', 'data' => $entries];
} else {
    $response = ['status' => 'error', 'message' => 'Belum ada data'];
}

$stmt->close();
jsonResponse($response);
exit;
$koneksi->close();