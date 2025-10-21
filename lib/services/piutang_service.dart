import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sia_mobile_soosvaldo/app_config.dart';
import 'package:sia_mobile_soosvaldo/models/piutang_model.dart';
import 'package:sia_mobile_soosvaldo/models/kartu_piutang_model.dart';

class PiutangService {
  Future<List<PiutangModel>> getPiutang() async {
    try {
      print("Fetch URL: ${AppConfig.baseUrl}get_piutang.php");
      final uri = Uri.parse('${AppConfig.baseUrl}get_piutang.php').replace(
        queryParameters: {'_ts': DateTime.now().millisecondsSinceEpoch.toString()},
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        final rawNon200 = utf8.decode(response.bodyBytes, allowMalformed: true);
        final snippet = rawNon200.length > 200 ? rawNon200.substring(0, 200) : rawNon200;
        print('Non-200 from get_piutang.php: ${response.statusCode} body: $snippet');
        throw Exception('Gagal memuat piutang: HTTP ${response.statusCode}');
      }
      try {
        print('Headers: ${response.headers}');
        print('Raw body >>>${response.body}<<<');
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded['status'] == 'error') {
          final msg = decoded['message']?.toString() ?? 'Server error saat memuat piutang';
          if (msg.toLowerCase().contains('belum ada data')) return <PiutangModel>[];
          throw Exception(msg);
        }
        final List<dynamic> dynamicList =
            decoded is List ? decoded : (decoded is Map && decoded['data'] is List ? decoded['data'] : []);
        return dynamicList.map((item) => PiutangModel.fromJson(item)).toList();
      } catch (e) {
        final rawErr = utf8.decode(response.bodyBytes, allowMalformed: true);
        final snippet = rawErr.length > 200 ? rawErr.substring(0, 200) : rawErr;
        print('Invalid JSON from get_piutang.php: $snippet');
        throw Exception('Respon server tidak valid saat memuat piutang');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<List<CicilanModel>> getCicilan(String kodePiutang) async {
    try {
      print("Fetch URL: ${AppConfig.baseUrl}get_cicilan.php?KODE_PIUTANG=$kodePiutang");
      final uri = Uri.parse('${AppConfig.baseUrl}get_cicilan.php').replace(
        queryParameters: {
          'KODE_PIUTANG': kodePiutang,
          '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        final rawNon200 = utf8.decode(response.bodyBytes, allowMalformed: true);
        final snippet = rawNon200.length > 200 ? rawNon200.substring(0, 200) : rawNon200;
        print('Non-200 from get_cicilan.php: ${response.statusCode} body: $snippet');
        throw Exception('Gagal memuat cicilan: HTTP ${response.statusCode}');
      }
      try {
        print('Headers: ${response.headers}');
        print('Raw body >>>${response.body}<<<');
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded['status'] == 'error') {
          final msg = decoded['message']?.toString() ?? 'Server error saat memuat cicilan';
          if (msg.toLowerCase().contains('belum ada data')) return <CicilanModel>[];
          throw Exception(msg);
        }
        final List<dynamic> dynamicList =
            decoded is List ? decoded : (decoded is Map && decoded['data'] is List ? decoded['data'] : []);
        return dynamicList.map((item) => CicilanModel.fromJson(item)).toList();
      } catch (e) {
        final rawErr = utf8.decode(response.bodyBytes, allowMalformed: true);
        final snippet = rawErr.length > 200 ? rawErr.substring(0, 200) : rawErr;
        print('Invalid JSON from get_cicilan.php: $snippet');
        throw Exception('Respon server tidak valid saat memuat cicilan');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> addCicilan(CicilanModel cicilan) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}add_cicilan.php');
      final response = await http.post(uri, body: {
        'ID_PIUTANG_CUSTOMER': cicilan.kodePiutang,
        'JUMLAH_BAYAR': cicilan.jumlah.toString(),
      });
      if (response.statusCode != 200) {
        throw Exception('Gagal menambah cicilan: HTTP ${response.statusCode}');
      }
      print('Headers: ${response.headers}');
      print('Raw body >>>${response.body}<<<');
      final decoded = json.decode(response.body);
      if (decoded is Map && decoded['status'] != 'success') {
        throw Exception(decoded['message']?.toString() ?? 'Gagal menambah cicilan');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}

extension KartuPiutangExtension on PiutangService {
  Future<List<KartuPiutangRow>> getKartuPiutangHistory(String kodePiutang) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}get_kartu_piutang.php').replace(
        queryParameters: {
          'KODE_PIUTANG': kodePiutang,
          '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        final rawNon200 = utf8.decode(response.bodyBytes, allowMalformed: true);
        final snippet = rawNon200.length > 200 ? rawNon200.substring(0, 200) : rawNon200;
        print('Non-200 from get_kartu_piutang.php: ${response.statusCode} body: $snippet');
        throw Exception('Gagal memuat histori kartu piutang: HTTP ${response.statusCode}');
      }
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded['status'] == 'error') {
          final msg = decoded['message']?.toString() ?? 'Server error saat memuat histori kartu piutang';
          if (msg.toLowerCase().contains('belum ada data')) return <KartuPiutangRow>[];
          throw Exception(msg);
        }
        final List<dynamic> dynamicList =
            decoded is List ? decoded : (decoded is Map && decoded['data'] is List ? decoded['data'] : []);
        return dynamicList.map((item) => KartuPiutangRow.fromJson(item)).toList();
      } catch (e) {
        final rawErr = utf8.decode(response.bodyBytes, allowMalformed: true);
        final snippet = rawErr.length > 200 ? rawErr.substring(0, 200) : rawErr;
        print('Invalid JSON from get_kartu_piutang.php: $snippet');
        throw Exception('Respon server tidak valid saat memuat histori kartu piutang');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}

// HAPUS fungsi top-level getPiutang yang duplikat dan menggunakan baseUrl tidak didefinisikan
