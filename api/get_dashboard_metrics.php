<?php
header('Content-Type: application/json; charset=utf-8');
// CORS untuk akses dari aplikasi web Flutter
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { echo json_encode(['status' => 'success']); exit; }
include 'config.php';
include_once __DIR__ . '/_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonResponse(['status' => 'error', 'message' => 'Invalid request method']);
    exit;
}

// Tentukan rentang tanggal berdasarkan parameter bulan (YYYY-MM) atau fallback ke bulan berjalan
$startDate = date('Y-m-01');
$endDate = date('Y-m-t');
if (isset($_GET['month'])) {
    $month = trim($_GET['month']); // format: YYYY-MM
    $ts = strtotime($month . '-01');
    if ($ts !== false) {
        $startDate = date('Y-m-01', $ts);
        $endDate = date('Y-m-t', $ts);
    }
}

// Perhitungan metrik dashboard (live)
// 1) Penjualan bulanan: sum(detail.qty * harga) untuk jurnal pada rentang bulan
$sqlMonthly = "SELECT COALESCE(SUM(dn.JUMLAH_BARANG * mb.HARGA_BARANG), 0) AS MONTHLY
    FROM JURNAL_UMUM ju
    JOIN DETAIL_NOTA_JUAL dn ON dn.NOMOR_NOTA = ju.REF
    JOIN MSTR_BARANG mb ON mb.KODE_BARANG = dn.KODE_BARANG
    WHERE ju.TANGGAL BETWEEN '$startDate' AND '$endDate'";
$resMonthly = $koneksi->query($sqlMonthly);
$monthlySales = 0.0;
if ($resMonthly && $resMonthly->num_rows > 0) {
    $r = cleanRow($resMonthly->fetch_assoc());
    $monthlySales = isset($r['MONTHLY']) ? (double)$r['MONTHLY'] : 0.0;
}

// 1b) Barang terjual (unit) bulan ini
$sqlSoldCount = "SELECT COALESCE(SUM(dn.JUMLAH_BARANG), 0) AS SOLD_COUNT
    FROM JURNAL_UMUM ju
    JOIN DETAIL_NOTA_JUAL dn ON dn.NOMOR_NOTA = ju.REF
    WHERE ju.TANGGAL BETWEEN '$startDate' AND '$endDate'";
$resSold = $koneksi->query($sqlSoldCount);
$soldCount = 0;
if ($resSold && $resSold->num_rows > 0) {
    $r = cleanRow($resSold->fetch_assoc());
    $soldCount = isset($r['SOLD_COUNT']) ? (int)$r['SOLD_COUNT'] : 0;
}

// 2) Piutang: hitung sisa per piutang dan status jatuh tempo/aging
$sqlPiutang = "SELECT ID_PIUTANG_CUSTOMER, NOMOR_NOTA, JUMLAH_PIUTANG, STATUS FROM PIUTANG_CUSTOMER";
$resPiutang = $koneksi->query($sqlPiutang);
$totalSisa = 0.0;
$soonDueCount = 0;
$defaultDueDays = 60;
$half = intdiv($defaultDueDays, 2);
if ($resPiutang && $resPiutang->num_rows > 0) {
    while ($row = $resPiutang->fetch_assoc()) {
        $row = cleanRow($row);
        $idPiutang = $row['ID_PIUTANG_CUSTOMER'];
        $nomorNota = $row['NOMOR_NOTA'];
        $jumlahPiutang = isset($row['JUMLAH_PIUTANG']) ? (double)$row['JUMLAH_PIUTANG'] : 0.0;
        $statusPiutang = isset($row['STATUS']) ? (int)$row['STATUS'] : 0;

        // Total cicilan dibayar
        $stmtC = $koneksi->prepare("SELECT COALESCE(SUM(JUMLAH_BAYAR), 0) AS TOTAL_BAYAR FROM TRS_CICILAN_PIUTANG WHERE ID_PIUTANG_CUSTOMER = ?");
        $stmtC->bind_param("s", $idPiutang);
        $stmtC->execute();
        $resC = $stmtC->get_result();
        $totalBayar = 0.0;
        if ($resC && $resC->num_rows > 0) {
            $rC = cleanRow($resC->fetch_assoc());
            $totalBayar = isset($rC['TOTAL_BAYAR']) ? (double)$rC['TOTAL_BAYAR'] : 0.0;
        }
        $stmtC->close();

        $sisa = max(0.0, $jumlahPiutang - $totalBayar);
        $totalSisa += $sisa;

        // Ambil tanggal nota dari jurnal
        $tanggalNota = null;
        if (!empty($nomorNota)) {
            $stmtT = $koneksi->prepare("SELECT TANGGAL FROM JURNAL_UMUM WHERE REF = ? ORDER BY CREATED_AT LIMIT 1");
            $stmtT->bind_param("s", $nomorNota);
            $stmtT->execute();
            $resT = $stmtT->get_result();
            if ($resT && $resT->num_rows > 0) {
                $rT = cleanRow($resT->fetch_assoc());
                $tanggalNota = $rT['TANGGAL'] ?? null;
            }
            $stmtT->close();
        }

        if ($tanggalNota) {
            $tsNota = strtotime($tanggalNota);
            $umurHari = (int)floor((strtotime(date('Y-m-d')) - $tsNota) / 86400);
            $dueDateTs = strtotime("+$defaultDueDays days", $tsNota);
            $isOverdue = ($statusPiutang === 1) && (time() > $dueDateTs);
            $isSoonDue = ($statusPiutang === 1) && !$isOverdue && ($umurHari >= $half);
            if ($isSoonDue) { $soonDueCount++; }
        }
    }
}

// 3) Customer count
$resCust = $koneksi->query("SELECT COUNT(*) AS CNT FROM CUSTOMER");
$customerCount = 0;
if ($resCust && $resCust->num_rows > 0) {
    $rc = cleanRow($resCust->fetch_assoc());
    $customerCount = isset($rc['CNT']) ? (int)$rc['CNT'] : 0;
}

// 4) Total stok barang
$resStok = $koneksi->query("SELECT COALESCE(SUM(JUMLAH_BARANG), 0) AS STOK FROM MSTR_BARANG");
$stokTotal = 0;
if ($resStok && $resStok->num_rows > 0) {
    $rs = cleanRow($resStok->fetch_assoc());
    $stokTotal = isset($rs['STOK']) ? (int)$rs['STOK'] : 0;
}

jsonResponse([
    'status' => 'success',
    'data' => [
        'monthly_sales' => $monthlySales,
        'soon_due_count' => $soonDueCount,
        'total_piutang_sisa' => $totalSisa,
        'customer_count' => $customerCount,
        'stok_total' => $stokTotal,
        'sold_count' => $soldCount,
    ]
]);
exit;
$koneksi->close();
// Tidak menutup tag PHP untuk mencegah output tak sengaja