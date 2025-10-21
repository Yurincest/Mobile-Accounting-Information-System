<?php
header('Content-Type: application/json; charset=utf-8');
include 'config.php';
include_once '_helper.php';
include 'generate_code.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(['status' => 'error', 'message' => 'Invalid request method']);
    exit;
}

// Ambil input dari form-data atau JSON body
$data = $_POST;
if (empty($data)) {
    $raw = file_get_contents('php://input');
    $decoded = json_decode($raw, true);
    if (is_array($decoded)) {
        $data = $decoded;
    }
}

$id_master = $data['ID_MASTER_MEMBERSHIP'] ?? null;
$nik_list = $data['NIK_CUSTOMER'] ?? ($data['NIK_CUSTOMER[]'] ?? null);
if (!is_array($nik_list) && $nik_list !== null) {
    // Jika dikirim single string, ubah ke array
    $nik_list = [$nik_list];
}

if ($id_master === null || empty($nik_list)) {
    jsonResponse(['status' => 'error', 'message' => 'ID_MASTER_MEMBERSHIP dan NIK_CUSTOMER[] wajib']);
    exit;
}

// Ambil info master membership
$stmtM = $koneksi->prepare("SELECT ID_MASTER_MEMBERSHIP, NAMA_MEMBERSHIP, HARGA_MEMBERSHIP, POTONGAN, STATUS FROM MASTER_MEMBERSHIP WHERE ID_MASTER_MEMBERSHIP = ?");
$stmtM->bind_param('s', $id_master);
$stmtM->execute();
$resM = $stmtM->get_result();
if (!$resM || $resM->num_rows === 0) {
    $stmtM->close();
    jsonResponse(['status' => 'error', 'message' => 'Master membership tidak ditemukan']);
    exit;
}
$master = cleanRow($resM->fetch_assoc());
$stmtM->close();

$nama_membership = $master['NAMA_MEMBERSHIP'] ?? '';
$harga_membership = isset($master['HARGA_MEMBERSHIP']) ? (double)$master['HARGA_MEMBERSHIP'] : 0.0;
$potongan = isset($master['POTONGAN']) ? (int)$master['POTONGAN'] : 0;

// Validasi edge-case: tolak jika customer masih memiliki membership aktif dari master yang sama
$duplicate = [];
foreach ($nik_list as $nik) {
    $nik = (string)$nik;
    // Skema TRANSAKSI_MEMBERSHIP tidak memiliki kolom STATUS; gunakan masa berlaku sebagai indikator aktif
    $sqlCheck = "SELECT 1 FROM TRANSAKSI_MEMBERSHIP WHERE ID_MASTER_MEMBERSHIP = ? AND NIK_CUSTOMER = ? AND TIMESTAMP_HABIS > NOW() LIMIT 1";
    $stmtC = $koneksi->prepare($sqlCheck);
    if (!$stmtC) {
        jsonResponse(['status' => 'error', 'message' => 'Prepare cek membership aktif gagal: ' . $koneksi->error]);
        exit;
    }
    $stmtC->bind_param('ss', $id_master, $nik);
    $stmtC->execute();
    $resC = $stmtC->get_result();
    if ($resC && $resC->num_rows > 0) {
        $duplicate[] = $nik;
    }
    $stmtC->close();
}

if (!empty($duplicate)) {
    jsonResponse(['status' => 'error', 'message' => 'Customer masih punya membership aktif', 'duplicates' => $duplicate]);
    exit;
}

$koneksi->begin_transaction();
$created = [];
$tanggal_jurnal = date('Y-m-d');

foreach ($nik_list as $nik) {
    $nik = (string)$nik;
    // Buat transaksi membership aktif (masa berlaku 60 hari)
    // Kolom STATUS tidak ada di TRANSAKSI_MEMBERSHIP; gunakan TIMESTAMP_HABIS sebagai indikator aktif
    $sqlTrx = "INSERT INTO TRANSAKSI_MEMBERSHIP (ID_TRANSAKSI_MEMBERSHIP, ID_MASTER_MEMBERSHIP, NIK_CUSTOMER, NAMA_MEMBERSHIP, HARGA_MEMBERSHIP, POTONGAN, TIMESTAMP_HABIS) VALUES (?, ?, ?, ?, ?, ?, DATE_ADD(NOW(), INTERVAL 60 DAY))";
    $stmtT = $koneksi->prepare($sqlTrx);
    if (!$stmtT) {
        $koneksi->rollback();
        jsonResponse(['status' => 'error', 'message' => 'Prepare transaksi membership gagal: ' . $koneksi->error]);
        exit;
    }
    $id_transaksi = generateCode('MBRTX');
    $stmtT->bind_param('ssssdi', $id_transaksi, $id_master, $nik, $nama_membership, $harga_membership, $potongan);
    if (!$stmtT->execute()) {
        $stmtT->close();
        $koneksi->rollback();
        jsonResponse(['status' => 'error', 'message' => 'Insert transaksi membership gagal: ' . $stmtT->error]);
        exit;
    }
    $stmtT->close();

    // Buat jurnal umum (Debit 1001, Kredit 4002)
    $ref = 'TRX-MBR-' . $nik;
    $keterangan = 'Pendapatan Membership - ' . $nama_membership . ' - Customer ' . $nik;

    $sqlJ = "INSERT INTO JURNAL_UMUM (TANGGAL, REF, KETERANGAN) VALUES (?, ?, ?)";
    $stmtJ = $koneksi->prepare($sqlJ);
    if (!$stmtJ) {
        $koneksi->rollback();
        jsonResponse(['status' => 'error', 'message' => 'Prepare jurnal umum gagal: ' . $koneksi->error]);
        exit;
    }
    $stmtJ->bind_param('sss', $tanggal_jurnal, $ref, $keterangan);
    if (!$stmtJ->execute()) {
        $stmtJ->close();
        $koneksi->rollback();
        jsonResponse(['status' => 'error', 'message' => 'Insert jurnal umum gagal: ' . $stmtJ->error]);
        exit;
    }
    $stmtJ->close();

    // Ambil ID_JURNAL_UMUM terbaru berdasarkan REF
    $id_jurnal_umum = null;
    $sqlGet = "SELECT ID_JURNAL_UMUM FROM JURNAL_UMUM WHERE REF = ? ORDER BY CREATED_AT DESC LIMIT 1";
    $stmtG = $koneksi->prepare($sqlGet);
    if (!$stmtG) {
        $koneksi->rollback();
        jsonResponse(['status' => 'error', 'message' => 'Prepare ambil ID_JURNAL_UMUM gagal: ' . $koneksi->error]);
        exit;
    }
    $stmtG->bind_param('s', $ref);
    $stmtG->execute();
    $resG = $stmtG->get_result();
    if ($resG && ($rowG = $resG->fetch_assoc())) {
        $id_jurnal_umum = $rowG['ID_JURNAL_UMUM'] ?? null;
    }
    $stmtG->close();

    if (!$id_jurnal_umum) {
        $koneksi->rollback();
        jsonResponse(['status' => 'error', 'message' => 'ID_JURNAL_UMUM tidak ditemukan setelah insert']);
        exit;
    }

    // Detail: Debit Kas (1001)
    $sqlD = "INSERT INTO JURNAL_DETAIL (ID_JURNAL_UMUM, KODE_AKUN, POSISI, NILAI) VALUES (?, ?, ?, ?)";
    $stmtD1 = $koneksi->prepare($sqlD);
    if (!$stmtD1) {
        $koneksi->rollback();
        jsonResponse(['status' => 'error', 'message' => 'Prepare jurnal detail (debit) gagal: ' . $koneksi->error]);
        exit;
    }
    $akun_kas = 1001; $pos_d = 'D'; $nilai = (double)$harga_membership;
    $stmtD1->bind_param('sisd', $id_jurnal_umum, $akun_kas, $pos_d, $nilai);
    if (!$stmtD1->execute()) {
        $stmtD1->close();
        $koneksi->rollback();
        jsonResponse(['status' => 'error', 'message' => 'Insert jurnal detail (debit) gagal: ' . $stmtD1->error]);
        exit;
    }
    $stmtD1->close();

    // Detail: Kredit Pendapatan Membership (4002)
    $stmtD2 = $koneksi->prepare($sqlD);
    if (!$stmtD2) {
        $koneksi->rollback();
        jsonResponse(['status' => 'error', 'message' => 'Prepare jurnal detail (kredit) gagal: ' . $koneksi->error]);
        exit;
    }
    $akun_pendapatan = 4002; $pos_k = 'K';
    $stmtD2->bind_param('sisd', $id_jurnal_umum, $akun_pendapatan, $pos_k, $nilai);
    if (!$stmtD2->execute()) {
        $stmtD2->close();
        $koneksi->rollback();
        jsonResponse(['status' => 'error', 'message' => 'Insert jurnal detail (kredit) gagal: ' . $stmtD2->error]);
        exit;
    }
    $stmtD2->close();

    $created[] = [
        'NIK_CUSTOMER' => $nik,
        'ID_TRANSAKSI_MEMBERSHIP' => $id_transaksi,
        'ID_JURNAL_UMUM' => $id_jurnal_umum,
        'NAMA_MEMBERSHIP' => $nama_membership,
        'HARGA_MEMBERSHIP' => $harga_membership,
        'POTONGAN' => $potongan
    ];
}

$koneksi->commit();
jsonResponse(['status' => 'success', 'message' => 'Member berhasil ditambahkan ke membership', 'data' => $created]);

?>