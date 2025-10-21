class MetodePembayaranModel {
  final String kodeMetode;
  final String namaMetode;
  final int status;

  MetodePembayaranModel({
    required this.kodeMetode,
    required this.namaMetode,
    required this.status,
  });

  factory MetodePembayaranModel.fromJson(Map<String, dynamic> json) {
    return MetodePembayaranModel(
      kodeMetode: json['KODE_METODE'],
      namaMetode: json['NAMA_METODE'],
      status: json['STATUS'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'KODE_METODE': kodeMetode,
      'NAMA_METODE': namaMetode,
      'STATUS': status,
    };
  }
}