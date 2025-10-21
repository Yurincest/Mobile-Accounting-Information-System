class KartuPiutangRow {
  final String? tanggal;
  final String keterangan;
  final double debit;
  final double kredit;
  final double saldo;

  KartuPiutangRow({
    required this.tanggal,
    required this.keterangan,
    required this.debit,
    required this.kredit,
    required this.saldo,
  });

  factory KartuPiutangRow.fromJson(Map<String, dynamic> json) {
    return KartuPiutangRow(
      tanggal: json['TANGGAL'] == null ? null : json['TANGGAL'].toString(),
      keterangan: json['KETERANGAN']?.toString() ?? '',
      debit: double.tryParse(json['DEBIT']?.toString() ?? '0') ?? 0.0,
      kredit: double.tryParse(json['KREDIT']?.toString() ?? '0') ?? 0.0,
      saldo: double.tryParse(json['SALDO']?.toString() ?? '0') ?? 0.0,
    );
  }
}