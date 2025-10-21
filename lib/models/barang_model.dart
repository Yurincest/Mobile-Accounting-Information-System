class BarangModel {
  final String kodeBarang;
  final String namaBarang;
  final double hargaBarang;
  final int stokBarang;
  final int status;

  BarangModel({
    required this.kodeBarang,
    required this.namaBarang,
    required this.hargaBarang,
    required this.stokBarang,
    required this.status,
  });

  factory BarangModel.fromJson(Map<String, dynamic> json) {
    return BarangModel(
      kodeBarang: json['KODE_BARANG'],
      namaBarang: json['NAMA_BARANG'],
      // HARGA_BARANG bisa berupa int/string/double -> pakai parse aman
      hargaBarang: double.parse(json['HARGA_BARANG'].toString()),
      // Stok pada SQL: JUMLAH_BARANG; fallback ke STOK_BARANG jika API lama
      stokBarang: int.parse((json['JUMLAH_BARANG'] ?? json['STOK_BARANG'] ?? 0).toString()),
      status: int.parse((json['STATUS'] ?? 0).toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'KODE_BARANG': kodeBarang,
      'NAMA_BARANG': namaBarang,
      'HARGA_BARANG': hargaBarang,
      // Saat kirim ke server, gunakan JUMLAH_BARANG sebagai nama kolom standar
      'JUMLAH_BARANG': stokBarang,
      'STATUS': status,
    };
  }
}