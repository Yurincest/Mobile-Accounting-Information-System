import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sia_mobile_soosvaldo/app_config.dart';
import 'package:sia_mobile_soosvaldo/models/barang_model.dart';

class BarangService {
  // Hapus: final String baseUrl = AppConfig.baseUrl;

  Future<List<BarangModel>> getBarang() async {
    try {
      print("Fetch URL: ${AppConfig.baseUrl}get_barang.php");
      final uri = Uri.parse('${AppConfig.baseUrl}get_barang.php').replace(
        queryParameters: {'_ts': DateTime.now().millisecondsSinceEpoch.toString()},
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Non-200 from get_barang.php: ${response.statusCode} body: $snippet');
        throw Exception('Gagal memuat barang: HTTP ${response.statusCode}');
      }
      try {
        print('Headers: ${response.headers}');
        print('Raw body >>>${response.body}<<<');
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded['status'] == 'error') {
          final msg = decoded['message']?.toString() ?? 'Server error saat memuat barang';
          // Jika server bilang belum ada data, kembalikan list kosong
          if (msg.toLowerCase().contains('belum ada data')) return <BarangModel>[];
          throw Exception(msg);
        }
        final List<dynamic> dynamicList =
            decoded is List ? decoded : (decoded is Map && decoded['data'] is List ? decoded['data'] : []);
        return dynamicList.map((item) => BarangModel.fromJson(item)).toList();
      } catch (e) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Invalid JSON from get_barang.php: $snippet');
        throw Exception('Respon server tidak valid saat memuat barang');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<BarangModel> addBarang(BarangModel barang) async {
    try {
      print("Fetch URL: ${AppConfig.baseUrl}add_barang.php");
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}add_barang.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(barang.toJson()..remove('KODE_BARANG')), // Remove kode because it's generated
      );
      if (response.statusCode != 200) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Non-200 from add_barang.php: ${response.statusCode} body: $snippet');
        throw Exception('Gagal menambah barang: HTTP ${response.statusCode}');
      }
      try {
        final decoded = json.decode(response.body);
        if (decoded is! Map || decoded['status'] != 'success') {
          final msg = decoded is Map ? (decoded['message']?.toString() ?? 'Gagal menambah barang') : 'Gagal menambah barang';
          throw Exception(msg);
        }
        final kode = (decoded['data'] is Map) ? decoded['data']['KODE_BARANG'] : null;
        if (kode == null) {
          throw Exception('Respon server tidak mengandung KODE_BARANG');
        }
        return BarangModel(
          kodeBarang: kode,
          namaBarang: barang.namaBarang,
          hargaBarang: barang.hargaBarang,
          stokBarang: barang.stokBarang,
          status: barang.status,
        );
      } catch (e) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Invalid JSON from add_barang.php: $snippet');
        throw Exception('Respon server tidak valid saat menambah barang');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<BarangModel> updateBarang(BarangModel barang) async {
    try {
      print("Fetch URL: ${AppConfig.baseUrl}update_barang.php");
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}update_barang.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(barang.toJson()),
      );
      if (response.statusCode != 200) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Non-200 from update_barang.php: ${response.statusCode} body: $snippet');
        throw Exception('Gagal memperbarui barang: HTTP ${response.statusCode}');
      }
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded['status'] != 'success') {
          throw Exception(decoded['message']?.toString() ?? 'Gagal memperbarui barang');
        }
        return barang;
      } catch (e) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Invalid JSON from update_barang.php: $snippet');
        throw Exception('Respon server tidak valid saat memperbarui barang');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> deleteBarang(String kode) async {
    try {
      print("Fetch URL: ${AppConfig.baseUrl}delete_barang.php");
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}delete_barang.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'KODE_BARANG': kode}),
      );
      if (response.statusCode != 200) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Non-200 from delete_barang.php: ${response.statusCode} body: $snippet');
        throw Exception('Gagal menghapus barang: HTTP ${response.statusCode}');
      }
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded['status'] != 'success') {
          throw Exception(decoded['message']?.toString() ?? 'Gagal menghapus barang');
        }
      } catch (e) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Invalid JSON from delete_barang.php: $snippet');
        throw Exception('Respon server tidak valid saat menghapus barang');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Hapus cleaning manual: parsing harus pakai body penuh tanpa trim/split
}