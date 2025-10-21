class MembershipWithCustomerModel {
  final String idMasterMembership;
  final String nikKaryawan;
  final String namaMembership;
  final double hargaMembership;
  final int potongan;
  final int status; // 1 = aktif, 0 = nonaktif
  final String namaCustomer;
  final String? timestampHabis; // Masa aktif terakhir
  final bool hasActiveMembership; // Apakah masih ada membership aktif
  final int? sisaHari; // Sisa hari masa aktif

  MembershipWithCustomerModel({
    required this.idMasterMembership,
    required this.nikKaryawan,
    required this.namaMembership,
    required this.hargaMembership,
    required this.potongan,
    required this.status,
    required this.namaCustomer,
    this.timestampHabis,
    required this.hasActiveMembership,
    this.sisaHari,
  });

  factory MembershipWithCustomerModel.fromJson(Map<String, dynamic> json) {
    return MembershipWithCustomerModel(
      idMasterMembership: json['ID_MASTER_MEMBERSHIP'],
      nikKaryawan: json['NIK_KARYAWAN'].toString(),
      namaMembership: json['NAMA_MEMBERSHIP'],
      hargaMembership: double.parse(json['HARGA_MEMBERSHIP'].toString()),
      potongan: int.parse(json['POTONGAN'].toString()),
      status: json['STATUS'],
      namaCustomer: json['NAMA_CUSTOMER'] ?? '',
      timestampHabis: json['TIMESTAMP_HABIS'],
      hasActiveMembership: json['HAS_ACTIVE_MEMBERSHIP'] == 1,
      sisaHari: json['SISA_HARI'] != null ? int.tryParse(json['SISA_HARI'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID_MASTER_MEMBERSHIP': idMasterMembership,
      'NIK_KARYAWAN': nikKaryawan,
      'NAMA_MEMBERSHIP': namaMembership,
      'HARGA_MEMBERSHIP': hargaMembership,
      'POTONGAN': potongan,
      'STATUS': status,
      'NAMA_CUSTOMER': namaCustomer,
      'TIMESTAMP_HABIS': timestampHabis,
      'HAS_ACTIVE_MEMBERSHIP': hasActiveMembership ? 1 : 0,
      'SISA_HARI': sisaHari,
    };
  }
}