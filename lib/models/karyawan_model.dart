class KaryawanModel {
  final String nikKaryawan;
  final String namaKaryawan;
  final String email;
  final String password;

  KaryawanModel({
    required this.nikKaryawan,
    required this.namaKaryawan,
    required this.email,
    required this.password,
  });

  factory KaryawanModel.fromJson(Map<String, dynamic> json) {
    return KaryawanModel(
      nikKaryawan: json['NIK_KARYAWAN']?.toString() ?? '',
      namaKaryawan: json['NAMA_KARYAWAN'] ?? '',
      email: json['EMAIL'] ?? '',
      password: json['PASSWORD'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'NIK_KARYAWAN': nikKaryawan,
      'NAMA_KARYAWAN': namaKaryawan,
      'EMAIL': email,
      'PASSWORD': password,
    };
  }
}