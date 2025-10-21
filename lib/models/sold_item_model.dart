class SoldItem {
  final String kodeBarang;
  final String namaBarang;
  final int qty;

  SoldItem({required this.kodeBarang, required this.namaBarang, required this.qty});

  factory SoldItem.fromJson(Map<String, dynamic> json) {
    return SoldItem(
      kodeBarang: (json['KODE_BARANG'] ?? '').toString(),
      namaBarang: (json['NAMA_BARANG'] ?? '').toString(),
      qty: int.tryParse((json['QTY'] ?? '0').toString()) ?? 0,
    );
  }
}