import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sia_mobile_soosvaldo/app_config.dart';
import 'package:sia_mobile_soosvaldo/models/membership_type_model.dart';

class MembershipTypeService {
  Future<List<MembershipTypeModel>> getMembershipTypes() async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}get_membership_type.php').replace(
        queryParameters: {'_ts': DateTime.now().millisecondsSinceEpoch.toString()},
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Gagal memuat membership type: HTTP ${response.statusCode}');
      }
      final decoded = json.decode(response.body);
      final List<dynamic> list = decoded is Map && decoded['data'] is List ? decoded['data'] : [];
      return list.map((e) => MembershipTypeModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<MembershipTypeModel> addMembershipType(MembershipTypeModel type) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}add_membership_type.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'NAMA_MEMBERSHIP': type.namaMembership,
          'HARGA_MEMBERSHIP': type.hargaMembership,
          'POTONGAN': type.potongan,
          'STATUS': type.status,
        }),
      );
      if (response.statusCode != 200) {
        throw Exception('Gagal menambah membership type: HTTP ${response.statusCode}');
      }
      return type;
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> updateMembershipType(MembershipTypeModel type) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}update_membership_type.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(type.toJson()),
      );
      if (response.statusCode != 200) {
        throw Exception('Gagal mengupdate membership type: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> assignMembershipFromType({
    required String idMembershipType,
    required String nikCustomer,
    int status = 1,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}assign_membership_from_type.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'ID_MEMBERSHIP_TYPE': idMembershipType,
          'NIK_CUSTOMER': nikCustomer,
          'STATUS': status,
        }),
      );
      if (response.statusCode != 200) {
        throw Exception('Gagal assign membership: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}