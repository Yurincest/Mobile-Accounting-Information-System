<?php
header('Content-Type: application/json; charset=utf-8');
include 'config.php';
include_once __DIR__ . '/_helper.php';

// Mengembalikan alias sesuai ekspektasi Flutter
// KODE_NOTA => NOMOR_NOTA
// KODE_METODE => ID_MPEM
// TANGGAL => dari JURNAL_UMUM.REF == NOMOR_NOTA (jika ada) atau null
// TOTAL => SUM(detail.qty * harga_barang)
// DP => TOTAL - SISA (SISA = JUMLAH_PIUTANG - TOTAL_CICILAN), minimal 0
// STATUS => ambil dari NOTA_JUAL.STATUS bila ada; jika null: 1 bila SISA>0, 0 bila SISA==0

$sql = "SELECT 
    N.NOMOR_NOTA, 
    N.NIK_CUSTOMER, 
    N.NIK_KARYAWAN, 
    N.ID_MPEM,
    C.NAMA_CUSTOMER,
    M.NAMA_MPEM
FROM NOTA_JUAL N
LEFT JOIN CUSTOMER C ON C.NIK_CUSTOMER = N.NIK_CUSTOMER
LEFT JOIN MSTR_METODE_PEMBAYARAN M ON M.ID_MPEM = N.ID_MPEM
ORDER BY N.NOMOR_NOTA DESC";
$result = $koneksi->query($sql);

if ($result && $result->num_rows > 0) {
    $notas = [];
    while ($row = $result->fetch_assoc()) {
        $row = cleanRow($row);
        $nomorNota = $row['NOMOR_NOTA'];
        $nikCustomer = $row['NIK_CUSTOMER'];
        $namaCustomer = $row['NAMA_CUSTOMER'] ?? $nikCustomer; // fallback ke NIK jika nama tidak ada
        $idMpem = $row['ID_MPEM'];
        $namaMetode = $row['NAMA_MPEM'] ?? $idMpem; // fallback ke ID jika nama tidak ada

        // Sanitasi field teks dari newline
        if ($nomorNota !== null) { $nomorNota = str_replace(["\r","\n"], ' ', $nomorNota); }
        if ($namaCustomer !== null) { $namaCustomer = str_replace(["\r","\n"], ' ', $namaCustomer); }
        if ($namaMetode !== null) { $namaMetode = str_replace(["\r","\n"], ' ', $namaMetode); }

        // Ambil tanggal dari JURNAL_UMUM berdasarkan REF
        $tanggal = null;
        $stmtT = $koneksi->prepare("SELECT TANGGAL FROM JURNAL_UMUM WHERE REF = ? ORDER BY CREATED_AT LIMIT 1");
        $stmtT->bind_param("s", $nomorNota);
        $stmtT->execute();
        $resT = $stmtT->get_result();
        if ($resT && $resT->num_rows > 0) {
            $rT = cleanRow($resT->fetch_assoc());
            $tanggal = $rT['TANGGAL'] ?? null;
        }
        $stmtT->close();

        // Hitung total dari DETAIL_NOTA_JUAL x harga barang
        $stmtTot = $koneksi->prepare("SELECT SUM(D.JUMLAH_BARANG * B.HARGA_BARANG) AS TOTAL FROM DETAIL_NOTA_JUAL D JOIN MSTR_BARANG B ON B.KODE_BARANG = D.KODE_BARANG WHERE D.NOMOR_NOTA = ?");
        $stmtTot->bind_param("s", $nomorNota);
        $stmtTot->execute();
        $resTot = $stmtTot->get_result();
        $total = 0.0;
        if ($resTot && $resTot->num_rows > 0) {
            $rTot = cleanRow($resTot->fetch_assoc());
            $total = isset($rTot['TOTAL']) ? (float)$rTot['TOTAL'] : 0.0;
        }
        $stmtTot->close();

        // Ambil piutang teragregasi untuk nota, stabil terhadap duplikasi historis
        $stmtP = $koneksi->prepare("SELECT COALESCE(SUM(JUMLAH_PIUTANG), 0) AS TOTAL_PIUTANG, COALESCE(MAX(STATUS), 0) AS STATUS_PIUTANG FROM PIUTANG_CUSTOMER WHERE NOMOR_NOTA = ?");
        $stmtP->bind_param("s", $nomorNota);
        $stmtP->execute();
        $resP = $stmtP->get_result();
        $jumlahPiutang = 0.0;
        $statusPiutang = 0; // default 0 (cash/lunas)
        if ($resP && $resP->num_rows > 0) {
            $rP = cleanRow($resP->fetch_assoc());
            $jumlahPiutang = isset($rP['TOTAL_PIUTANG']) ? (float)$rP['TOTAL_PIUTANG'] : 0.0;
            $statusPiutang = isset($rP['STATUS_PIUTANG']) ? (int)$rP['STATUS_PIUTANG'] : 0;
        }
        $stmtP->close();

        // Hitung total cicilan yang telah dibayar untuk semua piutang pada nota ini
        $stmtC = $koneksi->prepare("SELECT COALESCE(SUM(c.JUMLAH_BAYAR), 0) AS TOTAL_BAYAR
            FROM TRS_CICILAN_PIUTANG c
            JOIN PIUTANG_CUSTOMER p ON p.ID_PIUTANG_CUSTOMER = c.ID_PIUTANG_CUSTOMER
            WHERE p.NOMOR_NOTA = ?");
        $stmtC->bind_param("s", $nomorNota);
        $stmtC->execute();
        $resC = $stmtC->get_result();
        $totalBayar = 0.0;
        if ($resC && $resC->num_rows > 0) {
            $rC = cleanRow($resC->fetch_assoc());
            $totalBayar = isset($rC['TOTAL_BAYAR']) ? (float)$rC['TOTAL_BAYAR'] : 0.0;
        }
        $stmtC->close();

        // Sisa hutang = total piutang - total cicilan; minimal 0
        $sisa = max(0.0, $jumlahPiutang - $totalBayar);

        // DP = TOTAL - SISA (supaya Sisa di UI akurat berdasarkan cicilan)
        $dp = max(0.0, $total - $sisa);

        // Status: utamakan status di tabel NOTA_JUAL jika tersedia; jika tidak, turunkan dari sisa
        $notaStatus = null;
        $stmtNS = $koneksi->prepare("SELECT STATUS FROM NOTA_JUAL WHERE NOMOR_NOTA = ?");
        if ($stmtNS) {
            $stmtNS->bind_param("s", $nomorNota);
            $stmtNS->execute();
            $resNS = $stmtNS->get_result();
            if ($resNS && $resNS->num_rows > 0) {
                $rNS = cleanRow($resNS->fetch_assoc());
                $notaStatus = isset($rNS['STATUS']) ? (int)$rNS['STATUS'] : null;
            }
            $stmtNS->close();
        }
        $status = ($notaStatus !== null) ? (int)$notaStatus : (($sisa > 0.00001) ? 1 : 0);

        $notas[] = [
            'KODE_NOTA' => $nomorNota,
            'NIK_CUSTOMER' => $namaCustomer, // Ganti NIK dengan nama customer
            'KODE_METODE' => $namaMetode,    // Ganti kode dengan nama metode pembayaran
            'TANGGAL' => $tanggal,
            'TOTAL' => $total,
            'DP' => $dp,
            'STATUS' => $status,
        ];
    }
    $response = ['status' => 'success', 'data' => $notas];
} else {
    $response = ['status' => 'error', 'message' => 'Belum ada data'];
}

jsonResponse($response);
exit;
$koneksi->close();
// Tidak menutup tag PHP untuk mencegah output tak sengaja