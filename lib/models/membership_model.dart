class MembershipModel {
  final String idMasterMembership;
  final String nikKaryawan;
  final String namaMembership;
  final double hargaMembership;
  final int potongan;
  final int status; // 1 = aktif (Ready), 0 = nonaktif (Tidak Ready)

  MembershipModel({
    required this.idMasterMembership,
    required this.nikKaryawan,
    required this.namaMembership,
    required this.hargaMembership,
    required this.potongan,
    required this.status,
  });

  factory MembershipModel.fromJson(Map<String, dynamic> json) {
    return MembershipModel(
      idMasterMembership: json['ID_MASTER_MEMBERSHIP'],
      nikKaryawan: json['NIK_KARYAWAN'].toString(),
      namaMembership: json['NAMA_MEMBERSHIP'],
      hargaMembership: double.parse(json['HARGA_MEMBERSHIP'].toString()),
      potongan: int.parse(json['POTONGAN'].toString()),
      status: json['STATUS'],
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
    };
  }
}
