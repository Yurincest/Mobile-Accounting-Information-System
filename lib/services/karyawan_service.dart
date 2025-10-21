import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sia_mobile_soosvaldo/app_config.dart';
import 'package:sia_mobile_soosvaldo/models/karyawan_model.dart';

class KaryawanService {
  // Hapus: final String baseUrl = AppConfig.baseUrl;

  Future<List<KaryawanModel>> getKaryawan() async {
    try {
      print("Fetch URL: ${AppConfig.baseUrl}get_karyawan.php");
      final uri = Uri.parse('${AppConfig.baseUrl}get_karyawan.php').replace(
        queryParameters: {'_ts': DateTime.now().millisecondsSinceEpoch.toString()},
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Non-200 from get_karyawan.php: ${response.statusCode} body: $snippet');
        throw Exception('Gagal memuat karyawan: HTTP ${response.statusCode}');
      }
      try {
        print('Headers: ${response.headers}');
        print('Raw body >>>${response.body}<<<');
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded['status'] == 'error') {
          final msg = decoded['message']?.toString() ?? 'Server error saat memuat karyawan';
          if (msg.toLowerCase().contains('belum ada data')) return <KaryawanModel>[];
          throw Exception(msg);
        }
        final List<dynamic> dynamicList =
            decoded is List ? decoded : (decoded is Map && decoded['data'] is List ? decoded['data'] : []);
        return dynamicList.map((item) => KaryawanModel.fromJson(item)).toList();
      } catch (e) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Invalid JSON from get_karyawan.php: $snippet');
        throw Exception('Respon server tidak valid saat memuat karyawan');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<KaryawanModel> addKaryawan(KaryawanModel karyawan) async {
    try {
      print("Fetch URL: ${AppConfig.baseUrl}add_karyawan.php");
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}add_karyawan.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(karyawan.toJson()),
      );
      if (response.statusCode != 200) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Non-200 from add_karyawan.php: ${response.statusCode} body: $snippet');
        throw Exception('Gagal menambah karyawan: HTTP ${response.statusCode}');
      }
      try {
        final data = json.decode(response.body);
        if (data is Map && data['status'] != 'success') {
          throw Exception(data['message']?.toString() ?? 'Gagal menambah karyawan');
        }
        return karyawan;
      } catch (e) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Invalid JSON from add_karyawan.php: $snippet');
        throw Exception('Respon server tidak valid saat menambah karyawan');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<KaryawanModel> updateKaryawan(KaryawanModel karyawan) async {
    try {
      print("Fetch URL: ${AppConfig.baseUrl}update_karyawan.php");
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}update_karyawan.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(karyawan.toJson()),
      );
      if (response.statusCode != 200) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Non-200 from update_karyawan.php: ${response.statusCode} body: $snippet');
        throw Exception('Gagal memperbarui karyawan: HTTP ${response.statusCode}');
      }
      try {
        final data = json.decode(response.body);
        if (data is Map && data['status'] != 'success') {
          throw Exception(data['message']?.toString() ?? 'Gagal memperbarui karyawan');
        }
        return karyawan;
      } catch (e) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Invalid JSON from update_karyawan.php: $snippet');
        throw Exception('Respon server tidak valid saat memperbarui karyawan');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> deleteKaryawan(String nik) async {
    try {
      print("Fetch URL: ${AppConfig.baseUrl}delete_karyawan.php");
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}delete_karyawan.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'NIK_KARYAWAN': nik}),
      );
      if (response.statusCode != 200) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Non-200 from delete_karyawan.php: ${response.statusCode} body: $snippet');
        throw Exception('Gagal menghapus karyawan: HTTP ${response.statusCode}');
      }
      try {
        final data = json.decode(response.body);
        if (data is Map && data['status'] != 'success') {
          throw Exception(data['message']?.toString() ?? 'Gagal menghapus karyawan');
        }
      } catch (e) {
        final snippet = response.body.length > 200
            ? response.body.substring(0, 200)
            : response.body;
        print('Invalid JSON from delete_karyawan.php: $snippet');
        throw Exception('Respon server tidak valid saat menghapus karyawan');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<KaryawanModel> login(String email, String password) async {
    try {
      print("Fetch URL: ${AppConfig.baseUrl}login.php");
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}login.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );
  
      if (response.statusCode != 200) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Non-200 from login.php: ${response.statusCode} body: $snippet');
        throw Exception('Gagal login: HTTP ${response.statusCode}');
      }
      try {
        final data = json.decode(response.body);
        if (data is Map) {
          if (data['status'] == 'success') {
            return KaryawanModel.fromJson((data['data'] ?? {}) as Map<String, dynamic>);
          }
          final msg = data['message']?.toString() ?? 'Login gagal';
          throw Exception(msg);
        } else {
          throw Exception('Respon server tidak valid saat login');
        }
      } catch (e) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Invalid JSON from login.php: $snippet');
        throw Exception('Respon server tidak valid saat login');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Hapus cleaning manual: parsing harus pakai body penuh tanpa trim/split
}
