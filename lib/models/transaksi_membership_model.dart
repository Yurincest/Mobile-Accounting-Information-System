class TransaksiMembershipModel {
  final String idTransaksiMembership;
  final String idMasterMembership;
  final String nikCustomer;
  final String namaMembership;
  final double hargaMembership;
  final int potongan;
  final String timestampHabis; // ISO string

  TransaksiMembershipModel({
    required this.idTransaksiMembership,
    required this.idMasterMembership,
    required this.nikCustomer,
    required this.namaMembership,
    required this.hargaMembership,
    required this.potongan,
    required this.timestampHabis,
  });

  factory TransaksiMembershipModel.fromJson(Map<String, dynamic> json) {
    return TransaksiMembershipModel(
      idTransaksiMembership: json['ID_TRANSAKSI_MEMBERSHIP'] ?? '',
      idMasterMembership: json['ID_MASTER_MEMBERSHIP'] ?? '',
      nikCustomer: json['NIK_CUSTOMER']?.toString() ?? '',
      namaMembership: json['NAMA_MEMBERSHIP'] ?? '',
      hargaMembership: double.tryParse(json['HARGA_MEMBERSHIP'].toString()) ?? 0,
      potongan: int.tryParse(json['POTONGAN'].toString()) ?? 0,
      timestampHabis: json['TIMESTAMP_HABIS']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID_TRANSAKSI_MEMBERSHIP': idTransaksiMembership,
      'ID_MASTER_MEMBERSHIP': idMasterMembership,
      'NIK_CUSTOMER': nikCustomer,
      'NAMA_MEMBERSHIP': namaMembership,
      'HARGA_MEMBERSHIP': hargaMembership,
      'POTONGAN': potongan,
      'TIMESTAMP_HABIS': timestampHabis,
    };
  }
}