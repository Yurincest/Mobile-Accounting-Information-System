class MemberEntry {
  final String idTransaksiMembership;
  final String nikCustomer;
  final String namaCustomer;
  final String? timestampHabis;
  final int? sisaHari;
  final int status; // 1 aktif, 0 nonaktif

  MemberEntry({
    required this.idTransaksiMembership,
    required this.nikCustomer,
    required this.namaCustomer,
    this.timestampHabis,
    this.sisaHari,
    required this.status,
  });

  factory MemberEntry.fromJson(Map<String, dynamic> json) {
    return MemberEntry(
      idTransaksiMembership: (json['ID_TRANSAKSI_MEMBERSHIP'] ?? '').toString(),
      nikCustomer: (json['NIK_CUSTOMER'] ?? '').toString(),
      namaCustomer: (json['NAMA_CUSTOMER'] ?? '').toString(),
      timestampHabis: json['TIMESTAMP_HABIS']?.toString(),
      sisaHari: json['SISA_HARI'] == null ? null : int.tryParse(json['SISA_HARI'].toString()),
      status: int.tryParse(json['STATUS']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID_TRANSAKSI_MEMBERSHIP': idTransaksiMembership,
      'NIK_CUSTOMER': nikCustomer,
      'NAMA_CUSTOMER': namaCustomer,
      'TIMESTAMP_HABIS': timestampHabis,
      'SISA_HARI': sisaHari,
      'STATUS': status,
    };
  }
}

class MembershipDetailModel {
  final String idMasterMembership;
  final String namaMembership;
  final double hargaMembership;
  final int potongan;
  final int status; // 1 ready, 0 tidak ready
  final bool hasActiveMembership;
  final int? sisaHari; // maksimum sisa hari aktif
  final String? timestampHabis; // timestamp aktif terakhir
  final List<MemberEntry> customers;

  MembershipDetailModel({
    required this.idMasterMembership,
    required this.namaMembership,
    required this.hargaMembership,
    required this.potongan,
    required this.status,
    required this.hasActiveMembership,
    this.sisaHari,
    this.timestampHabis,
    this.customers = const [],
  });

  factory MembershipDetailModel.fromJson(Map<String, dynamic> json) {
    final rawCustomers = json['CUSTOMERS'];
    final List<MemberEntry> customers = rawCustomers is List
        ? rawCustomers
            .whereType<Map>()
            .map((e) => MemberEntry.fromJson(e.cast<String, dynamic>()))
            .toList()
        : [];

    return MembershipDetailModel(
      idMasterMembership: (json['ID_MASTER_MEMBERSHIP'] ?? '').toString(),
      namaMembership: (json['NAMA_MEMBERSHIP'] ?? '').toString(),
      hargaMembership: double.tryParse((json['HARGA_MEMBERSHIP'] ?? 0).toString()) ?? 0.0,
      potongan: int.tryParse((json['POTONGAN'] ?? 0).toString()) ?? 0,
      status: int.tryParse((json['STATUS'] ?? 0).toString()) ?? 0,
      hasActiveMembership: ((json['HAS_ACTIVE_MEMBERSHIP'] ?? 0).toString() == '1'),
      sisaHari: json['SISA_HARI'] == null ? null : int.tryParse(json['SISA_HARI'].toString()),
      timestampHabis: json['TIMESTAMP_HABIS']?.toString(),
      customers: customers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID_MASTER_MEMBERSHIP': idMasterMembership,
      'NAMA_MEMBERSHIP': namaMembership,
      'HARGA_MEMBERSHIP': hargaMembership,
      'POTONGAN': potongan,
      'STATUS': status,
      'HAS_ACTIVE_MEMBERSHIP': hasActiveMembership ? 1 : 0,
      'SISA_HARI': sisaHari,
      'TIMESTAMP_HABIS': timestampHabis,
      'CUSTOMERS': customers.map((e) => e.toJson()).toList(),
    };
  }
}