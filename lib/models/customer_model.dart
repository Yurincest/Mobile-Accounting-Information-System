class CustomerModel {
  final String nikCustomer;
  final String namaCustomer;
  final String email;

  CustomerModel({
    required this.nikCustomer,
    required this.namaCustomer,
    required this.email,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      nikCustomer: json['NIK_CUSTOMER']?.toString() ?? '',
      namaCustomer: json['NAMA_CUSTOMER'] ?? '',
      email: json['EMAIL'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'NIK_CUSTOMER': nikCustomer,
      'NAMA_CUSTOMER': namaCustomer,
      'EMAIL': email,
    };
  }
}