import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sia_mobile_soosvaldo/app_config.dart';
import 'package:sia_mobile_soosvaldo/models/accounting_model.dart';

class AccountingService {
  Future<List<JurnalUmumModel>> getJurnalUmum({String? startDate, String? endDate}) async {
    try {
      print("Fetch URL: ${AppConfig.baseUrl}get_jurnal_umum.php");
      final paramsJU = <String, String>{
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
      };
      final uri = Uri.parse('${AppConfig.baseUrl}get_jurnal_umum.php').replace(queryParameters: paramsJU);
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        final rawNon200 = utf8.decode(response.bodyBytes, allowMalformed: true);
        final snippet = rawNon200.length > 200 ? rawNon200.substring(0, 200) : rawNon200;
        print('Non-200 from get_jurnal_umum.php: ${response.statusCode} body: $snippet');
        throw Exception('Gagal memuat jurnal umum: HTTP ${response.statusCode}');
      }
      try {
        print('Headers: ${response.headers}');
        print('Raw body >>>${response.body}<<<');
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded['status'] == 'error') {
          final msg = decoded['message']?.toString() ?? 'Server error saat memuat jurnal umum';
          if (msg.toLowerCase().contains('belum ada data')) return <JurnalUmumModel>[];
          throw Exception(msg);
        }
        final List<dynamic> dynamicList =
            decoded is List ? decoded : (decoded is Map && decoded['data'] is List ? decoded['data'] : []);
        return dynamicList.map((item) => JurnalUmumModel.fromJson(item)).toList();
      } catch (e) {
        final rawErr = utf8.decode(response.bodyBytes, allowMalformed: true);
        final snippet = rawErr.length > 200 ? rawErr.substring(0, 200) : rawErr;
        print('Invalid JSON from get_jurnal_umum.php: $snippet');
        throw Exception('Respon server tidak valid saat memuat jurnal umum');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<MonthlySummary> getMonthlySummary({String? startDate, String? endDate}) async {
    try {
      final paramsJU = <String, String>{
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
      };
      final uri = Uri.parse('${AppConfig.baseUrl}get_jurnal_umum.php').replace(queryParameters: paramsJU);
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        final rawNon200 = utf8.decode(response.bodyBytes, allowMalformed: true);
        final snippet = rawNon200.length > 200 ? rawNon200.substring(0, 200) : rawNon200;
        print('Non-200 from get_jurnal_umum.php (summary): ${response.statusCode} body: $snippet');
        throw Exception('Gagal memuat ringkasan bulanan: HTTP ${response.statusCode}');
      }
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded['status'] == 'success') {
          final summaryRaw = decoded['summary'] ?? {};
          if (summaryRaw is Map) {
            return MonthlySummary.fromJson(summaryRaw.cast<String, dynamic>());
          }
        }
        // Fallback: ringkas dari data detail neraca jika tidak tersedia
        return MonthlySummary(totalDebit: 0.0, totalKredit: 0.0);
      } catch (_) {
        throw Exception('Respon server tidak valid saat memuat ringkasan bulanan');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<List<JurnalDetailModel>> getJurnalDetail(String kodeJurnal) async {
    try {
      // Backend sekarang mengharuskan ID_JURNAL_UMUM; pakai nilai kodeJurnal sebagai ID
      print("Fetch URL: ${AppConfig.baseUrl}get_jurnal_detail.php?ID_JURNAL_UMUM=$kodeJurnal");
      final uri = Uri.parse('${AppConfig.baseUrl}get_jurnal_detail.php').replace(
        queryParameters: {
          'ID_JURNAL_UMUM': kodeJurnal,
          '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        final rawNon200 = utf8.decode(response.bodyBytes, allowMalformed: true);
        final snippet = rawNon200.length > 200 ? rawNon200.substring(0, 200) : rawNon200;
        print('Non-200 from get_jurnal_detail.php: ${response.statusCode} body: $snippet');
        throw Exception('Gagal memuat jurnal detail: HTTP ${response.statusCode}');
      }
      try {
        print('Headers: ${response.headers}');
        print('Raw body >>>${response.body}<<<');
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded['status'] == 'error') {
          final msg = decoded['message']?.toString() ?? 'Server error saat memuat jurnal detail';
          if (msg.toLowerCase().contains('belum ada data')) return <JurnalDetailModel>[];
          throw Exception(msg);
        }
        final List<dynamic> dynamicList = decoded is List
            ? decoded
            : (decoded is Map && decoded['data'] is List ? decoded['data'] : []);
        return dynamicList.map((item) => JurnalDetailModel.fromJson(item)).toList();
      } on FormatException catch (_) {
        final rawErr = utf8.decode(response.bodyBytes, allowMalformed: true);
        final snippet = rawErr.length > 200 ? rawErr.substring(0, 200) : rawErr;
        print('Invalid JSON from get_jurnal_detail.php: $snippet');
        throw Exception('Respon server tidak valid saat memuat jurnal detail');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<List<BukuBesarEntry>> getBukuBesar(String kodeAkun, {String? startDate, String? endDate}) async {
    try {
      print("Fetch URL: ${AppConfig.baseUrl}get_buku_besar.php");
      final paramsBB = <String, String>{
        'KODE_AKUN': kodeAkun,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
      };
      final uri = Uri.parse('${AppConfig.baseUrl}get_buku_besar.php').replace(queryParameters: paramsBB);
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        final rawNon200 = utf8.decode(response.bodyBytes, allowMalformed: true);
        final snippet = rawNon200.length > 200 ? rawNon200.substring(0, 200) : rawNon200;
        print('Non-200 from get_buku_besar.php: ${response.statusCode} body: $snippet');
        throw Exception('Gagal memuat buku besar: HTTP ${response.statusCode}');
      }
      try {
        print('Headers: ${response.headers}');
        print('Raw body >>>${response.body}<<<');
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded['status'] == 'error') {
          final msg = decoded['message']?.toString() ?? 'Server error saat memuat buku besar';
          if (msg.toLowerCase().contains('belum ada data')) return <BukuBesarEntry>[];
          throw Exception(msg);
        }
        final List<dynamic> dynamicList =
            decoded is List ? decoded : (decoded is Map && decoded['data'] is List ? decoded['data'] : []);
        return dynamicList.map((item) => BukuBesarEntry.fromJson(item)).toList();
      } catch (e) {
        final rawErr = utf8.decode(response.bodyBytes, allowMalformed: true);
        final snippet = rawErr.length > 200 ? rawErr.substring(0, 200) : rawErr;
        print('Invalid JSON from get_buku_besar.php: $snippet');
        throw Exception('Respon server tidak valid saat memuat buku besar');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<List<NeracaSaldoModel>> getNeracaSaldo({String? startDate, String? endDate}) async {
    try {
      print("Fetch URL: ${AppConfig.baseUrl}get_neraca_saldo.php");
      final paramsNS = <String, String>{
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
      };
      final uri = Uri.parse('${AppConfig.baseUrl}get_neraca_saldo.php').replace(queryParameters: paramsNS);
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        final rawNon200 = utf8.decode(response.bodyBytes, allowMalformed: true);
        final snippet = rawNon200.length > 200 ? rawNon200.substring(0, 200) : rawNon200;
        print('Non-200 from get_neraca_saldo.php: ${response.statusCode} body: $snippet');
        throw Exception('Gagal memuat neraca saldo: HTTP ${response.statusCode}');
      }
      try {
        print('Headers: ${response.headers}');
        print('Raw body >>>${response.body}<<<');
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded['status'] == 'error') {
          final msg = decoded['message']?.toString() ?? 'Server error saat memuat neraca saldo';
          if (msg.toLowerCase().contains('belum ada data')) return <NeracaSaldoModel>[];
          throw Exception(msg);
        }
        final List<dynamic> dynamicList =
            decoded is List ? decoded : (decoded is Map && decoded['data'] is List ? decoded['data'] : []);
        return dynamicList.map((item) => NeracaSaldoModel.fromJson(item)).toList();
      } catch (e) {
        final rawErr = utf8.decode(response.bodyBytes, allowMalformed: true);
        final snippet = rawErr.length > 200 ? rawErr.substring(0, 200) : rawErr;
        print('Invalid JSON from get_neraca_saldo.php: $snippet');
        throw Exception('Respon server tidak valid saat memuat neraca saldo');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<List<KodeAkunModel>> getKodeAkun() async {
    try {
      print("Fetch URL: ${AppConfig.baseUrl}get_kode_akun.php");
      final uri = Uri.parse('${AppConfig.baseUrl}get_kode_akun.php').replace(
        queryParameters: {'_ts': DateTime.now().millisecondsSinceEpoch.toString()},
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        final rawNon200 = utf8.decode(response.bodyBytes, allowMalformed: true);
        final snippet = rawNon200.length > 200 ? rawNon200.substring(0, 200) : rawNon200;
        print('Non-200 from get_kode_akun.php: ${response.statusCode} body: $snippet');
        throw Exception('Gagal memuat kode akun: HTTP ${response.statusCode}');
      }
      try {
        print('Headers: ${response.headers}');
        print('Raw body >>>${response.body}<<<');
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded['status'] == 'error') {
          final msg = decoded['message']?.toString() ?? 'Server error saat memuat kode akun';
          if (msg.toLowerCase().contains('belum ada data')) return <KodeAkunModel>[];
          throw Exception(msg);
        }
        final List<dynamic> dynamicList =
            decoded is List ? decoded : (decoded is Map && decoded['data'] is List ? decoded['data'] : []);
        return dynamicList.map((item) => KodeAkunModel.fromJson(item)).toList();
      } catch (e) {
        final rawErr = utf8.decode(response.bodyBytes, allowMalformed: true);
        final snippet = rawErr.length > 200 ? rawErr.substring(0, 200) : rawErr;
        print('Invalid JSON from get_kode_akun.php: $snippet');
        throw Exception('Respon server tidak valid saat memuat kode akun');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

}