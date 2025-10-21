<?php
header('Content-Type: application/json; charset=utf-8');
include 'config.php';
include_once __DIR__ . '/_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonResponse(['status' => 'error', 'message' => 'Invalid request method']);
    exit;
}

$start_date = $_GET['start_date'] ?? '';
$end_date = $_GET['end_date'] ?? '';

$sql = "SELECT ID_JURNAL_UMUM, TANGGAL, KETERANGAN FROM JURNAL_UMUM";
$params = [];
$types = "";

if (!empty($start_date) && !empty($end_date)) {
    $sql .= " WHERE TANGGAL BETWEEN ? AND ?";
    $types = "ss";
    $params[] = $start_date;
    $params[] = $end_date;
}

$sql .= " ORDER BY CREATED_AT";

if (!empty($params)) {
    $stmt = $koneksi->prepare($sql);
    $stmt->bind_param($types, ...$params);
    $stmt->execute();
    $result = $stmt->get_result();
} else {
    $result = $koneksi->query($sql);
}

$jurnals = [];
if ($result && $result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $row = cleanRow($row);
        // Sanitasi newline pada field teks
        if (isset($row['KETERANGAN'])) {
            $row['KETERANGAN'] = str_replace(["\r","\n"], ' ', $row['KETERANGAN']);
        }
        $jurnals[] = [
            'ID_JURNAL_UMUM' => $row['ID_JURNAL_UMUM'] ?? null,
            'TANGGAL' => $row['TANGGAL'] ?? null,
            'KETERANGAN' => $row['KETERANGAN'] ?? null,
        ];
    }
    // Hitung ringkasan debit/kredit untuk periode yang difilter (atau keseluruhan jika tidak ada filter)
    $summaryDebit = 0.0;
    $summaryKredit = 0.0;
    $sqlSum = "SELECT 
            SUM(CASE WHEN jd.POSISI = 'D' THEN jd.NILAI ELSE 0 END) AS TOTAL_DEBIT,
            SUM(CASE WHEN jd.POSISI = 'K' THEN jd.NILAI ELSE 0 END) AS TOTAL_KREDIT
        FROM JURNAL_DETAIL jd 
        JOIN JURNAL_UMUM ju ON jd.ID_JURNAL_UMUM = ju.ID_JURNAL_UMUM";
    $typesSum = '';
    $paramsSum = [];
    if (!empty($start_date) && !empty($end_date)) {
        $sqlSum .= " WHERE ju.TANGGAL BETWEEN ? AND ?";
        $typesSum = 'ss';
        $paramsSum = [$start_date, $end_date];
    }
    if (!empty($typesSum)) {
        $stmtSum = $koneksi->prepare($sqlSum);
        if ($stmtSum) {
            $stmtSum->bind_param($typesSum, ...$paramsSum);
            $stmtSum->execute();
            $resSum = $stmtSum->get_result();
            if ($resSum && $resSum->num_rows > 0) {
                $rSum = cleanRow($resSum->fetch_assoc());
                $summaryDebit = isset($rSum['TOTAL_DEBIT']) ? (double)$rSum['TOTAL_DEBIT'] : 0.0;
                $summaryKredit = isset($rSum['TOTAL_KREDIT']) ? (double)$rSum['TOTAL_KREDIT'] : 0.0;
            }
            $stmtSum->close();
        }
    } else {
        // Jalankan tanpa filter
        $resSum = $koneksi->query($sqlSum);
        if ($resSum && $resSum->num_rows > 0) {
            $rSum = cleanRow($resSum->fetch_assoc());
            $summaryDebit = isset($rSum['TOTAL_DEBIT']) ? (double)$rSum['TOTAL_DEBIT'] : 0.0;
            $summaryKredit = isset($rSum['TOTAL_KREDIT']) ? (double)$rSum['TOTAL_KREDIT'] : 0.0;
        }
    }

    $response = [
        'status' => 'success',
        'data' => $jurnals,
        'summary' => [
            'TOTAL_DEBIT' => $summaryDebit,
            'TOTAL_KREDIT' => $summaryKredit,
        ],
    ];
} else {
    $response = ['status' => 'error', 'message' => 'Belum ada data'];
}

if (isset($stmt)) $stmt->close();
jsonResponse($response);
exit;
$koneksi->close();
// Tidak menutup tag PHP untuk mencegah output tak sengaja