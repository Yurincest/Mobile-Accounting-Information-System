class NotaJualModel {
  final String kodeNota;
  final String nikCustomer;
  final String kodeMetode;
  final String tanggal;
  final double total;
  final double dp;
  final int status;

  NotaJualModel({
    required this.kodeNota,
    required this.nikCustomer,
    required this.kodeMetode,
    required this.tanggal,
    required this.total,
    required this.dp,
    required this.status,
  });

  factory NotaJualModel.fromJson(Map<String, dynamic> json) {
    return NotaJualModel(
      kodeNota: json['KODE_NOTA'],
      nikCustomer: json['NIK_CUSTOMER'],
      kodeMetode: json['KODE_METODE'],
      tanggal: json['TANGGAL']?.toString() ?? '',
      total: double.parse(json['TOTAL'].toString()),
      dp: double.parse(json['DP'].toString()),
      status: json['STATUS'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'KODE_NOTA': kodeNota,
      'NIK_CUSTOMER': nikCustomer,
      'KODE_METODE': kodeMetode,
      'TANGGAL': tanggal,
      'TOTAL': total,
      'DP': dp,
      'STATUS': status,
    };
  }
}

class DetailNotaModel {
  final String kodeNota;
  final String kodeBarang;
  final String namaBarang;
  final int qty;
  final double harga;
  final double subtotal;

  DetailNotaModel({
    required this.kodeNota,
    required this.kodeBarang,
    required this.namaBarang,
    required this.qty,
    required this.harga,
    required this.subtotal,
  });

  factory DetailNotaModel.fromJson(Map<String, dynamic> json) {
    return DetailNotaModel(
      kodeNota: json['KODE_NOTA'],
      kodeBarang: json['KODE_BARANG'],
      namaBarang: json['NAMA_BARANG'] ?? json['KODE_BARANG'],
      qty: json['QTY'],
      harga: double.parse(json['HARGA'].toString()),
      subtotal: double.parse(json['SUBTOTAL'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'KODE_NOTA': kodeNota,
      'KODE_BARANG': kodeBarang,
      'NAMA_BARANG': namaBarang,
      'QTY': qty,
      'HARGA': harga,
      'SUBTOTAL': subtotal,
    };
  }
}