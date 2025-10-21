class MembershipTypeModel {
  final String idMembershipType;
  final String namaMembership;
  final double hargaMembership;
  final int potongan;
  final int status;

  MembershipTypeModel({
    required this.idMembershipType,
    required this.namaMembership,
    required this.hargaMembership,
    required this.potongan,
    required this.status,
  });

  factory MembershipTypeModel.fromJson(Map<String, dynamic> json) {
    return MembershipTypeModel(
      idMembershipType: json['ID_MEMBERSHIP_TYPE'] ?? '',
      namaMembership: json['NAMA_MEMBERSHIP'] ?? '',
      hargaMembership: (json['HARGA_MEMBERSHIP'] is int)
          ? (json['HARGA_MEMBERSHIP'] as int).toDouble()
          : (json['HARGA_MEMBERSHIP'] ?? 0.0).toDouble(),
      potongan: json['POTONGAN'] is int
          ? json['POTONGAN']
          : int.tryParse(json['POTONGAN']?.toString() ?? '0') ?? 0,
      status: json['STATUS'] is int
          ? json['STATUS']
          : int.tryParse(json['STATUS']?.toString() ?? '1') ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID_MEMBERSHIP_TYPE': idMembershipType,
      'NAMA_MEMBERSHIP': namaMembership,
      'HARGA_MEMBERSHIP': hargaMembership,
      'POTONGAN': potongan,
      'STATUS': status,
    };
  }
}