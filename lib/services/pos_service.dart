import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sia_mobile_soosvaldo/app_config.dart';
import 'package:sia_mobile_soosvaldo/models/nota_jual_model.dart';

class PosService {
  Future<List<NotaJualModel>> getNotaJual() async {
    try {
      print("Fetch URL: ${AppConfig.baseUrl}get_nota_jual.php");
      final uri = Uri.parse('${AppConfig.baseUrl}get_nota_jual.php').replace(
        queryParameters: {'_ts': DateTime.now().millisecondsSinceEpoch.toString()},
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Non-200 from get_nota_jual.php: ${response.statusCode} body: $snippet');
        throw Exception('Gagal memuat nota jual: HTTP ${response.statusCode}');
      }
      try {
        print('Headers: ${response.headers}');
        print('Raw body >>>${response.body}<<<');
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded['status'] == 'error') {
          final msg = decoded['message']?.toString() ?? 'Server error saat memuat nota jual';
          if (msg.toLowerCase().contains('belum ada data')) return <NotaJualModel>[];
          throw Exception(msg);
        }
        final List<dynamic> dynamicList =
            decoded is List ? decoded : (decoded is Map && decoded['data'] is List ? decoded['data'] : []);
        return dynamicList.map((item) => NotaJualModel.fromJson(item)).toList();
      } catch (e) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Invalid JSON from get_nota_jual.php: $snippet');
        throw Exception('Respon server tidak valid saat memuat nota jual');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<List<DetailNotaModel>> getDetailNota(String kodeNota) async {
    try {
      print("Fetch URL: ${AppConfig.baseUrl}get_detail_nota.php?KODE_NOTA=$kodeNota");
      final uri = Uri.parse('${AppConfig.baseUrl}get_detail_nota.php').replace(
        queryParameters: {
          'KODE_NOTA': kodeNota,
          '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Non-200 from get_detail_nota.php: ${response.statusCode} body: $snippet');
        throw Exception('Gagal memuat detail nota: HTTP ${response.statusCode}');
      }
      try {
        print('Headers: ${response.headers}');
        print('Raw body >>>${response.body}<<<');
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded['status'] == 'error') {
          final msg = decoded['message']?.toString() ?? 'Server error saat memuat detail nota';
          if (msg.toLowerCase().contains('belum ada data')) return <DetailNotaModel>[];
          throw Exception(msg);
        }
        final List<dynamic> dynamicList =
            decoded is List ? decoded : (decoded is Map && decoded['data'] is List ? decoded['data'] : []);
        return dynamicList.map((item) => DetailNotaModel.fromJson(item)).toList();
      } catch (e) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Invalid JSON from get_detail_nota.php: $snippet');
        throw Exception('Respon server tidak valid saat memuat detail nota');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<Map<String, dynamic>> addTransaksi(Map<String, dynamic> data) async {
    try {
      print("Fetch URL: ${AppConfig.baseUrl}add_nota_jual.php");
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}add_nota_jual.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode != 200) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Non-200 from add_nota_jual.php: ${response.statusCode} body: $snippet');
        throw Exception('Gagal menambah transaksi: HTTP ${response.statusCode}');
      }
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map) {
          if ((decoded['status'] ?? '').toString() != 'success') {
            final msg = decoded['message']?.toString() ?? 'Gagal menambah transaksi';
            throw Exception(msg);
          }
          return decoded.cast<String, dynamic>();
        }
        throw Exception('Format respons tidak terduga');
      } on FormatException catch (e) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Invalid JSON from add_nota_jual.php: $snippet');
        throw Exception('Respon server tidak valid saat menambah transaksi');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}

// Hapus cleaning manual: parsing harus pakai body penuh tanpa trim/split
