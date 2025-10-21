import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sia_mobile_soosvaldo/app_config.dart';
import 'package:sia_mobile_soosvaldo/models/transaksi_membership_model.dart';

class TransaksiMembershipService {
  Future<TransaksiMembershipModel?> getActiveMembership(String nikCustomer) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}get_active_membership.php').replace(
        queryParameters: {
          'NIK_CUSTOMER': nikCustomer,
          '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Non-200 from get_active_membership.php: ${response.statusCode} body: $snippet');
        throw Exception('Gagal memuat membership aktif: HTTP ${response.statusCode}');
      }
      try {
        print('Headers: ${response.headers}');
        print('Raw body >>>${response.body}<<<');
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded['status'] == 'error') {
          final msg = decoded['message']?.toString() ?? 'Membership aktif tidak ditemukan';
          if (msg.toLowerCase().contains('tidak ditemukan')) return null;
          throw Exception(msg);
        }
        final data = decoded is Map ? decoded['data'] : null;
        if (data is Map<String, dynamic>) {
          // Beberapa versi API mengembalikan satu objek
          return TransaksiMembershipModel.fromJson(data);
        }
        if (data is List) {
          // API get_active_membership.php mengembalikan array memberships dengan field: POTONGAN, HARGA_MEMBERSHIP, dll
          if (data.isEmpty) return null;
          // Ambil entri pertama yang relevan (karena kita sudah filter NIK di server)
          final first = data.first as Map<String, dynamic>;
          final members = first['members'];
          String? nik;
          String? ts;
          if (members is List && members.isNotEmpty) {
            final m0 = members.first as Map<String, dynamic>;
            nik = m0['NIK_CUSTOMER']?.toString();
            ts = m0['TIMESTAMP_HABIS']?.toString();
          }
          final normalized = {
            'ID_TRANSAKSI_MEMBERSHIP': '', // tidak disediakan oleh endpoint ini
            'ID_MASTER_MEMBERSHIP': first['ID_MASTER_MEMBERSHIP']?.toString() ?? '',
            'NIK_CUSTOMER': nik ?? nikCustomer,
            'NAMA_MEMBERSHIP': first['NAMA_MEMBERSHIP']?.toString() ?? '',
            'HARGA_MEMBERSHIP': first['HARGA_MEMBERSHIP'] ?? 0,
            'POTONGAN': first['POTONGAN'] ?? 0,
            'TIMESTAMP_HABIS': ts ?? '',
          };
          return TransaksiMembershipModel.fromJson(normalized);
        }
        return null;
      } catch (e) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Invalid JSON from get_active_membership.php: $snippet');
        throw Exception('Respon server tidak valid saat memuat membership aktif');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}