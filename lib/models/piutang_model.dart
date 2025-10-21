class PiutangModel {
  final String kodePiutang;
  final String kodeNota;
  final String? tanggal;
  final String? tanggalLunas;
  final double total;
  final double sisa;
  final int status;
  // Tambahan: informasi customer
  final String? nikCustomer;
  final String? namaCustomer;
  // Tambahan: informasi jatuh tempo & aging
  final String? dueDate;
  final bool? isJatuhTempo;
  final int? umurHari;
  final String? kodeMetode;

  PiutangModel({
    required this.kodePiutang,
    required this.kodeNota,
    required this.tanggal,
    this.tanggalLunas,
    required this.total,
    required this.sisa,
    required this.status,
    this.nikCustomer,
    this.namaCustomer,
    this.dueDate,
    this.isJatuhTempo,
    this.umurHari,
    this.kodeMetode,
  });

  factory PiutangModel.fromJson(Map<String, dynamic> json) {
    return PiutangModel(
      kodePiutang: (json['KODE_PIUTANG'] ?? json['ID_PIUTANG_CUSTOMER'])?.toString() ?? '',
      kodeNota: (json['KODE_NOTA'] ?? json['NOMOR_NOTA'])?.toString() ?? '',
      tanggal: json['TANGGAL'] == null ? null : json['TANGGAL'].toString(),
      tanggalLunas: json.containsKey('TANGGAL_LUNAS') ? json['TANGGAL_LUNAS']?.toString() : null,
      total: double.parse((json['TOTAL'] ?? json['JUMLAH_PIUTANG']).toString()),
      sisa: double.parse(json['SISA'].toString()),
      status: json['STATUS'],
      nikCustomer: json.containsKey('NIK_CUSTOMER') ? json['NIK_CUSTOMER']?.toString() : null,
      namaCustomer: json.containsKey('NAMA_CUSTOMER') ? json['NAMA_CUSTOMER']?.toString() : null,
      dueDate: json.containsKey('DUE_DATE') ? json['DUE_DATE']?.toString() : null,
      isJatuhTempo: json.containsKey('IS_JATUH_TEMPO')
          ? (json['IS_JATUH_TEMPO'].toString() == '1' || json['IS_JATUH_TEMPO'].toString().toLowerCase() == 'true')
          : null,
      umurHari: json.containsKey('UMUR_HARI') ? int.tryParse(json['UMUR_HARI'].toString()) : null,
      kodeMetode: (json['KODE_METODE'] ?? json['ID_MPEM'])?.toString(),
    );
  }
}

class CicilanModel {
  final String kodeCicilan;
  final String kodePiutang;
  final String tanggal;
  final double jumlah;

  CicilanModel({
    required this.kodeCicilan,
    required this.kodePiutang,
    required this.tanggal,
    required this.jumlah,
  });

  factory CicilanModel.fromJson(Map<String, dynamic> json) {
    return CicilanModel(
      // Kompatibilitas: terima skema baru dan lama dari API
      kodeCicilan: (json['KODE_CICILAN'] ?? json['ID_CICILAN_PIUTANG'])?.toString() ?? '',
      kodePiutang: (json['KODE_PIUTANG'] ?? json['ID_PIUTANG_CUSTOMER'])?.toString() ?? '',
      tanggal: (json['TANGGAL'] ?? json['WAKTU_CICIL'])?.toString() ?? '',
      jumlah: double.parse((json['JUMLAH'] ?? json['JUMLAH_BAYAR']).toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'KODE_CICILAN': kodeCicilan,
      'KODE_PIUTANG': kodePiutang,
      'TANGGAL': tanggal,
      'JUMLAH': jumlah,
    };
  }
}