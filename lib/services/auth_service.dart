import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app_config.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print("Fetch URL: ${AppConfig.baseUrl}login.php");
      final response = await http.post(
        Uri.parse("${AppConfig.baseUrl}login.php"),
        body: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode != 200) {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}'
        };
      }

      final body = response.body;
      if (body.isEmpty) {
        return {'status': 'error', 'message': 'Empty response from server'};
      }

      final parsed = json.decode(body);
      if (parsed is Map<String, dynamic>) {
        // Jika login sukses, simpan data karyawan ke AppConfig
        if (parsed['status'] == 'success') {
          final dynamic payload = (parsed['data'] ?? parsed['user']);
          if (payload is Map) {
            AppConfig.nikKaryawan = payload['NIK_KARYAWAN']?.toString();
            AppConfig.namaKaryawan = payload['NAMA_KARYAWAN']?.toString();
            AppConfig.emailKaryawan = payload['EMAIL']?.toString();
          }
        }
        return parsed;
      } else {
        return {'status': 'error', 'message': 'Invalid response format'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Tidak bisa konek ke server, periksa baseUrl atau koneksi jaringan: $e'};
    }
  }
}