<?php
header('Content-Type: application/json; charset=utf-8');
include 'config.php';
include_once __DIR__ . '/_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonResponse(['status' => 'error', 'message' => 'Invalid request method']);
    exit;
}

// Ambil piutang dari skema baru dan hitung atribut turunan
$sql = "SELECT ID_PIUTANG_CUSTOMER, NOMOR_NOTA, JUMLAH_PIUTANG, STATUS FROM PIUTANG_CUSTOMER";
$result = $koneksi->query($sql);

$piutangs = [];
$defaultDueDays = 60; // fallback jika tidak tersedia
if ($result && $result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $row = cleanRow($row);
        $idPiutang = $row['ID_PIUTANG_CUSTOMER'];
        $nomorNota = isset($row['NOMOR_NOTA']) ? $row['NOMOR_NOTA'] : ($row['KODE_NOTA'] ?? null);
        $jumlahPiutang = isset($row['JUMLAH_PIUTANG']) ? (float)$row['JUMLAH_PIUTANG'] : 0.0;
        $statusPiutang = isset($row['STATUS']) ? (int)$row['STATUS'] : null;

        // Informasi nota: NIK_CUSTOMER & ID_MPEM
        $nikCustomer = null;
        $idMpem = null;
        if ($nomorNota) {
            $stmtN = $koneksi->prepare("SELECT NIK_CUSTOMER, ID_MPEM FROM NOTA_JUAL WHERE NOMOR_NOTA = ?");
            $stmtN->bind_param("s", $nomorNota);
            $stmtN->execute();
            $resN = $stmtN->get_result();
            if ($resN && $resN->num_rows > 0) {
                $rN = cleanRow($resN->fetch_assoc());
                $nikCustomer = $rN['NIK_CUSTOMER'] ?? null;
                $idMpem = $rN['ID_MPEM'] ?? null;
            }
            $stmtN->close();
        }

        // Nama customer
        $namaCustomer = null;
        if ($nikCustomer) {
            $stmtCst = $koneksi->prepare("SELECT NAMA_CUSTOMER FROM CUSTOMER WHERE NIK_CUSTOMER = ?");
            $stmtCst->bind_param("s", $nikCustomer);
            $stmtCst->execute();
            $resCst = $stmtCst->get_result();
            if ($resCst && $resCst->num_rows > 0) {
                $rc = cleanRow($resCst->fetch_assoc());
                $namaCustomer = $rc['NAMA_CUSTOMER'] ?? null;
                if ($namaCustomer !== null) {
                    $namaCustomer = str_replace(["\r","\n"], ' ', $namaCustomer);
                }
            }
            $stmtCst->close();
        }

        // Tanggal dari jurnal umum berdasarkan REF nomor nota
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

        // Hitung total cicilan
        $stmtC = $koneksi->prepare("SELECT COALESCE(SUM(JUMLAH_BAYAR), 0) AS TOTAL_BAYAR FROM TRS_CICILAN_PIUTANG WHERE ID_PIUTANG_CUSTOMER = ?");
        $stmtC->bind_param("s", $idPiutang);
        $stmtC->execute();
        $resC = $stmtC->get_result();
        $totalBayar = 0.0;
        if ($resC && $resC->num_rows > 0) {
            $r = cleanRow($resC->fetch_assoc());
            $totalBayar = isset($r['TOTAL_BAYAR']) ? (float)$r['TOTAL_BAYAR'] : 0.0;
        }
        $stmtC->close();

        $sisa = max(0.0, $jumlahPiutang - $totalBayar);

        // Ambil tanggal lunas jika sudah lunas
        $tanggalLunas = null;
        if ($sisa <= 0.0) {
            $stmtL = $koneksi->prepare("SELECT MAX(WAKTU_CICIL) AS TGL_LUNAS FROM TRS_CICILAN_PIUTANG WHERE ID_PIUTANG_CUSTOMER = ?");
            $stmtL->bind_param("s", $idPiutang);
            $stmtL->execute();
            $resL = $stmtL->get_result();
            if ($resL && $resL->num_rows > 0) {
                $rL = cleanRow($resL->fetch_assoc());
                $tanggalLunas = $rL['TGL_LUNAS'] ?? null;
            }
            $stmtL->close();
        }

        // Hitung due date dan aging dari tanggal nota
        $dueDate = null;
        $umurHari = null;
        if ($tanggalNota) {
            $tsNota = strtotime($tanggalNota);
            $dueDate = date('Y-m-d', strtotime("+$defaultDueDays days", $tsNota));
            $umurHari = (int)floor((strtotime(date('Y-m-d')) - $tsNota) / 86400);
        }
        $isJatuhTempo = ($statusPiutang === 1 && $dueDate && strtotime(date('Y-m-d')) > strtotime($dueDate)) ? 1 : 0;

        // Sanitasi teks pada NOMOR_NOTA
        if ($nomorNota !== null) {
            $nomorNota = str_replace(["\r","\n"], ' ', $nomorNota);
        }

        $piutangs[] = [
            'ID_PIUTANG_CUSTOMER' => $idPiutang,
            'NOMOR_NOTA' => $nomorNota,
            'JUMLAH_PIUTANG' => $jumlahPiutang,
            'STATUS' => $statusPiutang,
            'SISA' => $sisa,
            'IS_JATUH_TEMPO' => $isJatuhTempo,
            'UMUR_HARI' => $umurHari,
            // Informasi tambahan (opsional untuk UI)
            'TANGGAL' => $tanggalNota,
            'TANGGAL_LUNAS' => $tanggalLunas,
            'NIK_CUSTOMER' => $nikCustomer,
            'NAMA_CUSTOMER' => $namaCustomer,
            'ID_MPEM' => $idMpem,
            'DUE_DATE' => $dueDate,
        ];
    }
    $response = ['status' => 'success', 'data' => $piutangs];
} else {
    $response = ['status' => 'error', 'message' => 'Belum ada data'];
}

jsonResponse($response);
exit;
$koneksi->close();
// Tidak menutup tag PHP untuk mencegah output tak sengaja