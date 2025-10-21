import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sia_mobile_soosvaldo/app_config.dart';
import 'package:sia_mobile_soosvaldo/models/metrics_model.dart';
import 'package:sia_mobile_soosvaldo/models/sold_item_model.dart';

class MetricsService {
  Future<DashboardMetrics> getDashboardMetrics({String? month}) async {
    try {
      final base = Uri.parse('${AppConfig.baseUrl}get_dashboard_metrics.php');
      final url = base.replace(queryParameters: {
        if (month != null && month.isNotEmpty) 'month': month,
        '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
      });
      final response = await http.get(url);
      if (response.statusCode != 200) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        throw Exception('Gagal mengambil metrik: HTTP ${response.statusCode} $snippet');
      }
      final decoded = json.decode(response.body);
      if (decoded is Map && (decoded['status'] ?? '') == 'success') {
        final data = (decoded['data'] ?? {}) as Map<String, dynamic>;
        return DashboardMetrics.fromJson(data);
      }
      throw Exception('Respon metrik tidak valid');
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<List<SoldItem>> getSoldItemsDetail() async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}get_sold_items_detail.php');
      final response = await http.get(url);
      if (response.statusCode != 200) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        throw Exception('Gagal mengambil detail barang terjual: HTTP ${response.statusCode} $snippet');
      }
      final decoded = json.decode(response.body);
      if (decoded is Map && (decoded['status'] ?? '') == 'success') {
        final list = (decoded['data'] ?? []) as List<dynamic>;
        return list.map((e) => SoldItem.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('Respon detail barang terjual tidak valid');
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}