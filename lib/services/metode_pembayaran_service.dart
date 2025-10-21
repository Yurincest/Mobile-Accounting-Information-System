import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sia_mobile_soosvaldo/app_config.dart';
import 'package:sia_mobile_soosvaldo/models/metode_pembayaran_model.dart';

class MetodePembayaranService {
  Future<List<MetodePembayaranModel>> getMetodePembayaran() async {
    try {
      print("Fetch URL: ${AppConfig.baseUrl}get_metode_pembayaran.php");
      final uri = Uri.parse('${AppConfig.baseUrl}get_metode_pembayaran.php').replace(
        queryParameters: {'_ts': DateTime.now().millisecondsSinceEpoch.toString()},
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Non-200 from get_metode_pembayaran.php: ${response.statusCode} body: $snippet');
        throw Exception('Gagal memuat metode pembayaran: HTTP ${response.statusCode}');
      }
      try {
        print('Headers: ${response.headers}');
        print('Raw body >>>${response.body}<<<');
        final jsonResponse = json.decode(response.body);
        if (jsonResponse is Map && jsonResponse['status'] == 'error') {
          final msg = jsonResponse['message']?.toString() ?? 'Server error saat memuat metode pembayaran';
          if (msg.toLowerCase().contains('belum ada data')) return <MetodePembayaranModel>[];
          throw Exception(msg);
        }
        final List<dynamic> dynamicList =
            jsonResponse is List ? jsonResponse : (jsonResponse is Map && jsonResponse['data'] is List ? jsonResponse['data'] : []);
        return dynamicList.map((item) => MetodePembayaranModel.fromJson(item)).toList();
      } catch (e) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Invalid JSON from get_metode_pembayaran.php: $snippet');
        throw Exception('Respon server tidak valid saat memuat metode pembayaran');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<MetodePembayaranModel> addMetodePembayaran(MetodePembayaranModel metode) async {
    try {
      print("Fetch URL: ${AppConfig.baseUrl}add_metode_pembayaran.php");
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}add_metode_pembayaran.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(metode.toJson()),
      );
      if (response.statusCode != 200) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Non-200 from add_metode_pembayaran.php: ${response.statusCode} body: $snippet');
        throw Exception('Gagal menambah metode pembayaran: HTTP ${response.statusCode}');
      }
      try {
        final data = json.decode(response.body);
        if (data is Map && data['status'] != 'success') {
          throw Exception(data['message']?.toString() ?? 'Gagal menambah metode pembayaran');
        }
        return metode;
      } catch (e) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Invalid JSON from add_metode_pembayaran.php: $snippet');
        throw Exception('Respon server tidak valid saat menambah metode pembayaran');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<MetodePembayaranModel> updateMetodePembayaran(MetodePembayaranModel metode) async {
    try {
      print("Fetch URL: ${AppConfig.baseUrl}update_metode_pembayaran.php");
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}update_metode_pembayaran.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(metode.toJson()),
      );
      if (response.statusCode != 200) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Non-200 from update_metode_pembayaran.php: ${response.statusCode} body: $snippet');
        throw Exception('Gagal memperbarui metode pembayaran: HTTP ${response.statusCode}');
      }
      try {
        final data = json.decode(response.body);
        if (data is Map && data['status'] != 'success') {
          throw Exception(data['message']?.toString() ?? 'Gagal memperbarui metode pembayaran');
        }
        return metode;
      } catch (e) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Invalid JSON from update_metode_pembayaran.php: $snippet');
        throw Exception('Respon server tidak valid saat memperbarui metode pembayaran');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> deleteMetodePembayaran(String kode) async {
    try {
      print("Fetch URL: ${AppConfig.baseUrl}delete_metode_pembayaran.php");
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}delete_metode_pembayaran.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'KODE_METODE': kode}),
      );
      if (response.statusCode != 200) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Non-200 from delete_metode_pembayaran.php: ${response.statusCode} body: $snippet');
        throw Exception('Gagal menghapus metode pembayaran: HTTP ${response.statusCode}');
      }
      try {
        final data = json.decode(response.body);
        if (data is Map && data['status'] != 'success') {
          throw Exception(data['message']?.toString() ?? 'Gagal menghapus metode pembayaran');
        }
      } catch (e) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Invalid JSON from delete_metode_pembayaran.php: $snippet');
        throw Exception('Respon server tidak valid saat menghapus metode pembayaran');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}

// Hapus cleaning manual: parsing harus pakai body penuh tanpa trim/split