class JurnalUmumModel {
  final String kodeJurnal;
  final String tanggal;
  final String keterangan;

  JurnalUmumModel({
    required this.kodeJurnal,
    required this.tanggal,
    required this.keterangan,
  });

  factory JurnalUmumModel.fromJson(Map<String, dynamic> json) {
    return JurnalUmumModel(
      kodeJurnal: (json['KODE_JURNAL'] ?? json['ID_JURNAL_UMUM'] ?? '').toString(),
      tanggal: json['TANGGAL'],
      keterangan: json['KETERANGAN'],
    );
  }
}

class MonthlySummary {
  final double totalDebit;
  final double totalKredit;

  MonthlySummary({required this.totalDebit, required this.totalKredit});

  factory MonthlySummary.fromJson(Map<String, dynamic> json) {
    // Mendukung kedua format kunci: upper-case atau lower-case
    final td = json['TOTAL_DEBIT'] ?? json['total_debit'] ?? 0.0;
    final tk = json['TOTAL_KREDIT'] ?? json['total_kredit'] ?? 0.0;
    return MonthlySummary(
      totalDebit: (td is num) ? td.toDouble() : double.tryParse(td.toString()) ?? 0.0,
      totalKredit: (tk is num) ? tk.toDouble() : double.tryParse(tk.toString()) ?? 0.0,
    );
  }
}

class JurnalDetailModel {
  final String kodeJurnal;
  final String kodeAkun;
  final String namaAkun;
  final double debit;
  final double kredit;
  final List<JurnalItemDetail> items;

  JurnalDetailModel({
    required this.kodeJurnal,
    required this.kodeAkun,
    this.namaAkun = '',
    required this.debit,
    required this.kredit,
    this.items = const [],
  });

  factory JurnalDetailModel.fromJson(Map<String, dynamic> json) {
    // Backend dapat mengirim pasangan POSISI('D'/'K') + NILAI
    // atau langsung field DEBIT/KREDIT. Normalisasikan agar UI selalu konsisten.
    final kodeJurnal = (json['KODE_JURNAL'] ?? json['ID_JURNAL_UMUM'] ?? '').toString();
    final kodeAkun = json['KODE_AKUN']?.toString() ?? '';
    final namaAkun = json['NAMA_AKUN']?.toString() ?? '';

    double debit = 0.0;
    double kredit = 0.0;

    if (json.containsKey('DEBIT') || json.containsKey('KREDIT')) {
      // Format lama/alternatif: nilai sudah dipisah
      final d = json['DEBIT'];
      final k = json['KREDIT'];
      debit = d == null ? 0.0 : double.tryParse(d.toString()) ?? 0.0;
      kredit = k == null ? 0.0 : double.tryParse(k.toString()) ?? 0.0;
    } else {
      // Format baru: gunakan POSISI + NILAI
      final posisi = json['POSISI']?.toString().toUpperCase();
      final nilaiRaw = json['NILAI'];
      final nilai = nilaiRaw == null ? 0.0 : double.tryParse(nilaiRaw.toString()) ?? 0.0;
      if (posisi == 'D') {
        debit = nilai;
      } else if (posisi == 'K') {
        kredit = nilai;
      }
    }

    // Opsional: detail barang/penjualan per jurnal (bila backend menyediakan)
    final rawItems = json['ITEMS'] ?? json['items'] ?? json['DETAIL_BARANG'] ?? json['detail_barang'];
    List<JurnalItemDetail> items = const [];
    if (rawItems is List) {
      items = rawItems
          .whereType<Map>()
          .map((it) => JurnalItemDetail.fromJson(it.cast<String, dynamic>()))
          .toList();
    } else if (rawItems is Map && rawItems['data'] is List) {
      final list = rawItems['data'] as List;
      items = list
          .whereType<Map>()
          .map((it) => JurnalItemDetail.fromJson(it.cast<String, dynamic>()))
          .toList();
    }

    return JurnalDetailModel(
      kodeJurnal: kodeJurnal,
      kodeAkun: kodeAkun,
      namaAkun: namaAkun,
      debit: debit,
      kredit: kredit,
      items: items,
    );
  }
}

class JurnalItemDetail {
  final String namaBarang;
  final int qty;
  final double harga;
  final double subtotal;

  JurnalItemDetail({
    required this.namaBarang,
    required this.qty,
    required this.harga,
    required this.subtotal,
  });

  factory JurnalItemDetail.fromJson(Map<String, dynamic> json) {
    final nama = (json['NAMA_BARANG'] ?? json['nama_barang'] ?? json['BARANG'] ?? '').toString();
    final qRaw = json['QTY'] ?? json['qty'] ?? json['JUMLAH'] ?? 0;
    final hRaw = json['HARGA'] ?? json['harga'] ?? 0;
    final sRaw = json['SUBTOTAL'] ?? json['subtotal'] ?? ((hRaw is num ? hRaw.toDouble() : double.tryParse(hRaw.toString()) ?? 0.0) * (qRaw is num ? qRaw.toInt() : int.tryParse(qRaw.toString()) ?? 0));
    return JurnalItemDetail(
      namaBarang: nama,
      qty: qRaw is num ? qRaw.toInt() : int.tryParse(qRaw.toString()) ?? 0,
      harga: hRaw is num ? hRaw.toDouble() : double.tryParse(hRaw.toString()) ?? 0.0,
      subtotal: sRaw is num ? sRaw.toDouble() : double.tryParse(sRaw.toString()) ?? 0.0,
    );
  }
}

class BukuBesarEntry {
  final String tanggal;
  final String keterangan;
  final double debit;
  final double kredit;

  BukuBesarEntry({
    required this.tanggal,
    required this.keterangan,
    required this.debit,
    required this.kredit,
  });

  factory BukuBesarEntry.fromJson(Map<String, dynamic> json) {
    return BukuBesarEntry(
      tanggal: json['TANGGAL'],
      keterangan: json['KETERANGAN'],
      debit: double.parse(json['DEBIT'].toString()),
      kredit: double.parse(json['KREDIT'].toString()),
    );
  }
}

class NeracaSaldoModel {
  final String kodeAkun;
  final String namaAkun;
  final double totalDebit;
  final double totalKredit;
  final double saldo;

  NeracaSaldoModel({
    required this.kodeAkun,
    required this.namaAkun,
    required this.totalDebit,
    required this.totalKredit,
    required this.saldo,
  });

  factory NeracaSaldoModel.fromJson(Map<String, dynamic> json) {
    return NeracaSaldoModel(
      kodeAkun: json['KODE_AKUN'],
      namaAkun: json['NAMA_AKUN'],
      totalDebit: double.parse(json['TOTAL_DEBIT'].toString()),
      totalKredit: double.parse(json['TOTAL_KREDIT'].toString()),
      saldo: double.parse(json['SALDO'].toString()),
    );
  }
}

class KodeAkunModel {
  final String kodeAkun;
  final String namaAkun;

  KodeAkunModel({
    required this.kodeAkun,
    required this.namaAkun,
  });

  factory KodeAkunModel.fromJson(Map<String, dynamic> json) {
    return KodeAkunModel(
      kodeAkun: json['KODE_AKUN'],
      namaAkun: json['NAMA_AKUN'],
    );
  }
}