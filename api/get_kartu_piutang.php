<?php
header('Content-Type: application/json; charset=utf-8');
include 'config.php';
include_once __DIR__ . '/_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonResponse(['status' => 'error', 'message' => 'Invalid request method']);
    exit;
}

$kode_piutang = $_GET['KODE_PIUTANG'] ?? '';
if (empty($kode_piutang)) {
    jsonResponse(['status' => 'error', 'message' => 'Kode piutang diperlukan']);
    exit;
}

// Ambil data piutang utama
$stmtP = $koneksi->prepare("SELECT ID_PIUTANG_CUSTOMER, NOMOR_NOTA, JUMLAH_PIUTANG, STATUS FROM PIUTANG_CUSTOMER WHERE ID_PIUTANG_CUSTOMER = ?");
$stmtP->bind_param("s", $kode_piutang);
$stmtP->execute();
$resP = $stmtP->get_result();
if (!$resP || $resP->num_rows === 0) {
    jsonResponse(['status' => 'error', 'message' => 'Piutang tidak ditemukan']);
    exit;
}
$rowP = cleanRow($resP->fetch_assoc());
$idPiutang = $rowP['ID_PIUTANG_CUSTOMER'];
$nomorNota = isset($rowP['NOMOR_NOTA']) ? $rowP['NOMOR_NOTA'] : ($rowP['KODE_NOTA'] ?? null);
$jumlahPiutang = isset($rowP['JUMLAH_PIUTANG']) ? (float)$rowP['JUMLAH_PIUTANG'] : 0.0;
$statusPiutang = isset($rowP['STATUS']) ? (int)$rowP['STATUS'] : null;

// Tanggal nota (dari jurnal umum REF = nomor nota)
$tanggalNota = null;
if ($nomorNota) {
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

// Sanitasi teks pada NOMOR_NOTA agar tidak mengandung newline
if ($nomorNota !== null) {
    $nomorNota = str_replace(["\r","\n"], ' ', $nomorNota);
}

// Bangun histori debit–kredit dengan saldo berjalan
$rows = [];
$saldo = $jumlahPiutang;

// Baris awal: Nota Penjualan
$rows[] = [
    'TANGGAL' => $tanggalNota,
    'KETERANGAN' => $nomorNota ? ("Nota Penjualan " . $nomorNota) : 'Nota Penjualan',
    'DEBIT' => $jumlahPiutang,
    'KREDIT' => 0.0,
    'SALDO' => $saldo,
];

// Ambil cicilan terurut
$stmtC = $koneksi->prepare("SELECT ID_CICILAN_PIUTANG, WAKTU_CICIL, JUMLAH_BAYAR FROM TRS_CICILAN_PIUTANG WHERE ID_PIUTANG_CUSTOMER = ? ORDER BY WAKTU_CICIL ASC, ID_CICILAN_PIUTANG ASC");
$stmtC->bind_param("s", $idPiutang);
$stmtC->execute();
$resC = $stmtC->get_result();
$index = 1;
if ($resC && $resC->num_rows > 0) {
    while ($rc = $resC->fetch_assoc()) {
        $rc = cleanRow($rc);
        $tanggal = isset($rc['WAKTU_CICIL']) ? str_replace(["\r","\n"], ' ', $rc['WAKTU_CICIL']) : null;
        $bayar = isset($rc['JUMLAH_BAYAR']) ? (float)$rc['JUMLAH_BAYAR'] : 0.0;
        $saldo = max(0.0, $saldo - $bayar);
        $rows[] = [
            'TANGGAL' => $tanggal,
            'KETERANGAN' => $nomorNota ? ("Pembayaran Piutang " . $nomorNota . " – Cicilan ke-" . $index) : ("Pembayaran Piutang – Cicilan ke-" . $index),
            'DEBIT' => 0.0,
            'KREDIT' => $bayar,
            'SALDO' => $saldo,
        ];
        $index++;
    }
}
$stmtC->close();

jsonResponse(['status' => 'success', 'data' => $rows, 'meta' => [
    'ID_PIUTANG_CUSTOMER' => $idPiutang,
    'NOMOR_NOTA' => $nomorNota,
    'PIUTANG_AWAL' => $jumlahPiutang,
    'SISA' => $saldo,
    'STATUS' => $statusPiutang,
]]);
exit;

$koneksi->close();
// Tidak menutup tag PHP untuk mencegah output tak sengaja