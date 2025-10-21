<?php
header('Content-Type: application/json; charset=utf-8');
include 'config.php';
include_once '_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonResponse(['status' => 'error', 'message' => 'Invalid request method']);
    exit;
}

$kode_piutang = $_GET['KODE_PIUTANG'] ?? '';

if (empty($kode_piutang)) {
    jsonResponse(['status' => 'error', 'message' => 'Kode piutang diperlukan']);
    exit;
}

$sql = "SELECT c.ID_CICILAN_PIUTANG, c.ID_PIUTANG_CUSTOMER, c.WAKTU_CICIL, c.JUMLAH_BAYAR, p.STATUS AS status_piutang
        FROM TRS_CICILAN_PIUTANG c
        JOIN PIUTANG_CUSTOMER p ON p.ID_PIUTANG_CUSTOMER = c.ID_PIUTANG_CUSTOMER
        WHERE c.ID_PIUTANG_CUSTOMER = ?";
$stmt = $koneksi->prepare($sql);
$stmt->bind_param("s", $kode_piutang);
$stmt->execute();
$result = $stmt->get_result();

$cicilans = [];
if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $row = cleanRow($row);
        // Normalisasi kolom ke schema Flutter (KODE_*/TANGGAL/JUMLAH)
        $cicilans[] = [
            'KODE_CICILAN' => $row['ID_CICILAN_PIUTANG'] ?? null,
            'KODE_PIUTANG' => $row['ID_PIUTANG_CUSTOMER'] ?? null,
            // Hilangkan karakter newline yang dapat merusak parsing JSON di klien
            'TANGGAL' => isset($row['WAKTU_CICIL']) ? str_replace(["\r","\n"], ' ', $row['WAKTU_CICIL']) : null,
            'JUMLAH' => isset($row['JUMLAH_BAYAR']) ? (float)$row['JUMLAH_BAYAR'] : null,
            'status_piutang' => isset($row['status_piutang']) ? (int)$row['status_piutang'] : null,
        ];
    }
    jsonResponse(['status' => 'success', 'data' => $cicilans]);
    exit;
} else {
    jsonResponse(['status' => 'error', 'message' => 'Belum ada data']);
    exit;
}

$stmt->close();
$koneksi->close();
// Tidak menutup tag PHP untuk mencegah output tak sengaja