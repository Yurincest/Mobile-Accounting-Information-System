class DashboardMetrics {
  final double monthlySales;
  final int soonDueCount;
  final double totalPiutangSisa;
  final int customerCount;
  final int stokTotal;
  final int soldCount;

  DashboardMetrics({
    required this.monthlySales,
    required this.soonDueCount,
    required this.totalPiutangSisa,
    required this.customerCount,
    required this.stokTotal,
    required this.soldCount,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      monthlySales: double.parse((json['monthly_sales'] ?? 0).toString()),
      soonDueCount: int.parse((json['soon_due_count'] ?? 0).toString()),
      totalPiutangSisa: double.parse((json['total_piutang_sisa'] ?? 0).toString()),
      customerCount: int.parse((json['customer_count'] ?? 0).toString()),
      stokTotal: int.parse((json['stok_total'] ?? 0).toString()),
      soldCount: int.parse((json['sold_count'] ?? 0).toString()),
    );
  }
}