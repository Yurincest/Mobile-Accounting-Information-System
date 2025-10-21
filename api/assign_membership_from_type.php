<?php
header('Content-Type: application/json; charset=utf-8');
include 'config.php';
include 'generate_code.php';
include_once '_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(['status' => 'error', 'message' => 'Invalid request method']);
    exit;
}

$data = $_POST;
if (empty($data)) {
    $data = json_decode(file_get_contents('php://input'), true) ?? [];
}

if (!isset($data['ID_MEMBERSHIP_TYPE']) || !isset($data['NIK_CUSTOMER']) || !isset($data['STATUS'])) {
    jsonResponse(['status' => 'error', 'message' => 'ID_MEMBERSHIP_TYPE, NIK_CUSTOMER, STATUS are required']);
    exit;
}

$id_type = $data['ID_MEMBERSHIP_TYPE'];
$nik_customer = $data['NIK_CUSTOMER'];
$status = (int)$data['STATUS'];

// Pastikan tabel tipe tersedia
$sqlCreateType = "CREATE TABLE IF NOT EXISTS MASTER_MEMBERSHIP_TYPE (
  ID_MEMBERSHIP_TYPE varchar(10) NOT NULL,
  NAMA_MEMBERSHIP varchar(50) NOT NULL,
  HARGA_MEMBERSHIP decimal(25,0) NOT NULL,
  POTONGAN decimal(2,0) NOT NULL,
  STATUS decimal(1,0) NOT NULL,
  LAST_UPDATED timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ID_MEMBERSHIP_TYPE)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci";
$koneksi->query($sqlCreateType);

// Ambil detail tipe
$stmtType = $koneksi->prepare("SELECT NAMA_MEMBERSHIP, HARGA_MEMBERSHIP, POTONGAN, STATUS FROM MASTER_MEMBERSHIP_TYPE WHERE ID_MEMBERSHIP_TYPE = ?");
$stmtType->bind_param("s", $id_type);
$stmtType->execute();
$resType = $stmtType->get_result();
if (!$resType || $resType->num_rows === 0) {
    jsonResponse(['status' => 'error', 'message' => 'Membership type tidak ditemukan']);
    exit;
}
$rowType = cleanRow($resType->fetch_assoc());
$nama_membership = $rowType['NAMA_MEMBERSHIP'];
$harga_membership = isset($rowType['HARGA_MEMBERSHIP']) ? (double)$rowType['HARGA_MEMBERSHIP'] : 0.0;
$potongan = isset($rowType['POTONGAN']) ? (int)$rowType['POTONGAN'] : 0;
$status_type = isset($rowType['STATUS']) ? (int)$rowType['STATUS'] : 1;
$stmtType->close();

// Gunakan status dari request jika disediakan, jika tidak, dari type
if (!isset($data['STATUS'])) { $status = $status_type; }

// Buat baris assignment di MASTER_MEMBERSHIP sesuai skema lama (re-usable)
$koneksi->begin_transaction();
$id_master_membership = generateCode('MBR');
$sqlIns = "INSERT INTO MASTER_MEMBERSHIP (ID_MASTER_MEMBERSHIP, NIK_CUSTOMER, NAMA_MEMBERSHIP, HARGA_MEMBERSHIP, POTONGAN, STATUS, LAST_UPDATED) VALUES (?, ?, ?, ?, ?, ?, NOW())";
$stmtIns = $koneksi->prepare($sqlIns);
$stmtIns->bind_param("sssdii", $id_master_membership, $nik_customer, $nama_membership, $harga_membership, $potongan, $status);
if (!$stmtIns->execute()) {
    $koneksi->rollback();
    jsonResponse(['status' => 'error', 'message' => 'Insert MASTER_MEMBERSHIP gagal: ' . $stmtIns->error]);
    exit;
}
$stmtIns->close();

// Buat transaksi membership aktif 60 hari
$sqlTrx = "INSERT INTO TRANSAKSI_MEMBERSHIP (ID_TRANSAKSI_MEMBERSHIP, ID_MASTER_MEMBERSHIP, NIK_CUSTOMER, NAMA_MEMBERSHIP, HARGA_MEMBERSHIP, POTONGAN, TIMESTAMP_HABIS) VALUES (?, ?, ?, ?, ?, ?, DATE_ADD(NOW(), INTERVAL 60 DAY))";
$stmtTrx = $koneksi->prepare($sqlTrx);
if (!$stmtTrx) {
    $koneksi->rollback();
    jsonResponse(['status' => 'error', 'message' => 'Prepare TRANSAKSI_MEMBERSHIP gagal: ' . $koneksi->error]);
    exit;
}
$id_transaksi = '';
$stmtTrx->bind_param("ssssdi", $id_transaksi, $id_master_membership, $nik_customer, $nama_membership, $harga_membership, $potongan);
if (!$stmtTrx->execute()) {
    $stmtTrx->close();
    $koneksi->rollback();
    jsonResponse(['status' => 'error', 'message' => 'Insert TRANSAKSI_MEMBERSHIP gagal: ' . $stmtTrx->error]);
    exit;
}
$stmtTrx->close();

// Jurnal umum: header + detail (Debit Kas 1001, Kredit Pendapatan Membership 4002)
$tanggal_jurnal = date('Y-m-d');
$ref = 'TRX-MBR-' . $nik_customer;
    // Tambahkan label agar mudah dikenali di Jurnal Umum
    $ket = 'Pendapatan Membership - Assign Membership ' . $nama_membership . ' dari Type';
$stmtJ = $koneksi->prepare("INSERT INTO JURNAL_UMUM (TANGGAL, REF, KETERANGAN) VALUES (?, ?, ?)");
if (!$stmtJ) { $koneksi->rollback(); jsonResponse(['status' => 'error', 'message' => 'Prepare JURNAL_UMUM gagal: ' . $koneksi->error]); exit; }
$stmtJ->bind_param("sss", $tanggal_jurnal, $ref, $ket);
if (!$stmtJ->execute()) { $stmtJ->close(); $koneksi->rollback(); jsonResponse(['status' => 'error', 'message' => 'Insert JURNAL_UMUM gagal: ' . $stmtJ->error]); exit; }
$stmtJ->close();

$id_jurnal = null;
$stmtGet = $koneksi->prepare("SELECT ID_JURNAL_UMUM FROM JURNAL_UMUM WHERE REF = ? ORDER BY CREATED_AT DESC LIMIT 1");
$stmtGet->bind_param("s", $ref);
$stmtGet->execute();
$resGet = $stmtGet->get_result();
if ($resGet && $resGet->num_rows > 0) {
    $id_jurnal = cleanRow($resGet->fetch_assoc())['ID_JURNAL_UMUM'] ?? null;
}
$stmtGet->close();
if (!$id_jurnal) { $koneksi->rollback(); jsonResponse(['status' => 'error', 'message' => 'ID_JURNAL_UMUM tidak ditemukan setelah insert']); exit; }

$sqlD = "INSERT INTO JURNAL_DETAIL (ID_JURNAL_UMUM, KODE_AKUN, POSISI, NILAI) VALUES (?, ?, ?, ?)";
$stmtD1 = $koneksi->prepare($sqlD);
if (!$stmtD1) { $koneksi->rollback(); jsonResponse(['status' => 'error', 'message' => 'Prepare JURNAL_DETAIL(debit) gagal: ' . $koneksi->error]); exit; }
$akunKas = 1001; $posD = 'D'; $nilai = (double)$harga_membership;
$stmtD1->bind_param("sisd", $id_jurnal, $akunKas, $posD, $nilai);
if (!$stmtD1->execute()) { $stmtD1->close(); $koneksi->rollback(); jsonResponse(['status' => 'error', 'message' => 'Insert JURNAL_DETAIL(debit) gagal: ' . $stmtD1->error]); exit; }
$stmtD1->close();

$stmtD2 = $koneksi->prepare($sqlD);
if (!$stmtD2) { $koneksi->rollback(); jsonResponse(['status' => 'error', 'message' => 'Prepare JURNAL_DETAIL(kredit) gagal: ' . $koneksi->error]); exit; }
$akunPendapatan = 4002; $posK = 'K';
$stmtD2->bind_param("sisd", $id_jurnal, $akunPendapatan, $posK, $nilai);
if (!$stmtD2->execute()) { $stmtD2->close(); $koneksi->rollback(); jsonResponse(['status' => 'error', 'message' => 'Insert JURNAL_DETAIL(kredit) gagal: ' . $stmtD2->error]); exit; }
$stmtD2->close();

$koneksi->commit();
jsonResponse(['status' => 'success', 'message' => 'Membership berhasil di-assign dari type', 'data' => [[
  'ID_MASTER_MEMBERSHIP' => $id_master_membership,
  'ID_MEMBERSHIP_TYPE' => $id_type
]]]);
exit;

?>