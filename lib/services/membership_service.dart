import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sia_mobile_soosvaldo/app_config.dart';
import 'package:sia_mobile_soosvaldo/models/membership_model.dart';
import 'package:sia_mobile_soosvaldo/models/membership_with_customer_model.dart';
import 'package:sia_mobile_soosvaldo/models/membership_detail_model.dart';

class MembershipService {
  Future<List<MembershipWithCustomerModel>> getMembershipWithCustomer() async {
    try {
      print("Fetch URL: ${AppConfig.baseUrl}get_membership_with_customer.php");
      final uri = Uri.parse('${AppConfig.baseUrl}get_membership_with_customer.php').replace(
        queryParameters: {
          '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Non-200 from get_membership_with_customer.php: ${response.statusCode} body: $snippet');
        throw Exception('Gagal memuat membership: HTTP ${response.statusCode}');
      }
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded['status'] != 'success') {
          throw Exception(decoded['message']?.toString() ?? 'Gagal memuat membership');
        }
        final data = decoded['data'] as List;
        return data.map((item) => MembershipWithCustomerModel.fromJson(item)).toList();
      } catch (e) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Invalid JSON from get_membership_with_customer.php: $snippet');
        throw Exception('Respon server tidak valid saat memuat membership');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Versi detail: memuat daftar pelanggan per master membership (CUSTOMERS)
  Future<List<MembershipDetailModel>> getMembershipDetails() async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}get_membership_with_customer.php').replace(
        queryParameters: {'_ts': DateTime.now().millisecondsSinceEpoch.toString()},
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Non-200 from get_membership_with_customer.php: ${response.statusCode} body: $snippet');
        throw Exception('Gagal memuat membership: HTTP ${response.statusCode}');
      }
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded['status'] != 'success') {
          throw Exception(decoded['message']?.toString() ?? 'Gagal memuat membership');
        }
        final list = decoded is Map && decoded['data'] is List ? decoded['data'] as List : const [];
        return list.map((e) => MembershipDetailModel.fromJson(Map<String, dynamic>.from(e))).toList();
      } catch (e) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Invalid JSON from get_membership_with_customer.php: $snippet');
        throw Exception('Respon server tidak valid saat memuat membership');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<List<MembershipModel>> getMembership() async {
    try {
      print("Fetch URL: ${AppConfig.baseUrl}get_membership.php");
      final uri = Uri.parse('${AppConfig.baseUrl}get_membership.php').replace(
        queryParameters: {'_ts': DateTime.now().millisecondsSinceEpoch.toString()},
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Non-200 from get_membership.php: ${response.statusCode} body: $snippet');
        throw Exception('Gagal memuat membership: HTTP ${response.statusCode}');
      }
      try {
        print('Headers: ${response.headers}');
        print('Raw body >>>${response.body}<<<');
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded['status'] == 'error') {
          final msg = decoded['message']?.toString() ?? 'Server error saat memuat membership';
          if (msg.toLowerCase().contains('belum ada data')) return <MembershipModel>[];
          throw Exception(msg);
        }
        final List<dynamic> dynamicList =
            decoded is List ? decoded : (decoded is Map && decoded['data'] is List ? decoded['data'] : []);
        return dynamicList.map((item) => MembershipModel.fromJson(item)).toList();
      } catch (e) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Invalid JSON from get_membership.php: $snippet');
        throw Exception('Respon server tidak valid saat memuat membership');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> addMembership(MembershipModel membership) async {
    try {
      print("Fetch URL: ${AppConfig.baseUrl}add_membership.php");
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}add_membership.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'NAMA_MEMBERSHIP': membership.namaMembership,
          'HARGA_MEMBERSHIP': membership.hargaMembership,
          'POTONGAN': membership.potongan,
          'STATUS': membership.status,
        }),
      );
      if (response.statusCode != 200) {
        throw Exception('Gagal menambah membership: HTTP ${response.statusCode}');
      }
      final data = json.decode(response.body);
      if (data is Map && data['status'] != 'success') {
        throw Exception(data['message']?.toString() ?? 'Gagal menambah membership');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> updateMembership(MembershipModel membership) async {
    try {
      print("Fetch URL: ${AppConfig.baseUrl}update_membership.php");
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}update_membership.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'ID_MASTER_MEMBERSHIP': membership.idMasterMembership,
          'NAMA_MEMBERSHIP': membership.namaMembership,
          'HARGA_MEMBERSHIP': membership.hargaMembership,
          'POTONGAN': membership.potongan,
          'STATUS': membership.status,
        }),
      );
      if (response.statusCode != 200) {
        throw Exception('Gagal mengupdate membership: HTTP ${response.statusCode}');
      }
      final data = json.decode(response.body);
      if (data is Map && data['status'] != 'success') {
        throw Exception(data['message']?.toString() ?? 'Gagal mengupdate membership');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Assign banyak customer ke satu master membership, membuat transaksi aktif + jurnal per customer
  Future<void> addMembersToMaster({
    required String idMasterMembership,
    required List<String> nikCustomers,
  }) async {
    try {
      print("Fetch URL: ${AppConfig.baseUrl}add_member_to_membership.php");
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}add_member_to_membership.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'ID_MASTER_MEMBERSHIP': idMasterMembership,
          'NIK_CUSTOMER': nikCustomers,
        }),
      );
      if (response.statusCode != 200) {
        throw Exception('Gagal assign membership: HTTP ${response.statusCode}');
      }
      final data = json.decode(response.body);
      if (data is Map && data['status'] != 'success') {
        final msg = data['message']?.toString() ?? 'Gagal assign membership';
        if (data['duplicates'] is List && (data['duplicates'] as List).isNotEmpty) {
          throw Exception('$msg: sudah aktif untuk ${data['duplicates'].length} customer');
        }
        throw Exception(msg);
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Reaktivasi satu customer: buat transaksi baru + jurnal via endpoint add_member_to_membership.php
  Future<void> reactivateCustomer({
    required String idMasterMembership,
    required String nikCustomer,
  }) async {
    await addMembersToMaster(idMasterMembership: idMasterMembership, nikCustomers: [nikCustomer]);
  }

  // Update status transaksi membership per pelanggan
  Future<void> updateMemberStatus({
    String? idTransaksiMembership,
    String? idMasterMembership,
    String? nikCustomer,
    required int status,
  }) async {
    try {
      print("Fetch URL: ${AppConfig.baseUrl}update_member_status.php");
      final payload = {
        'STATUS': status,
        if (idTransaksiMembership != null) 'ID_TRANSAKSI_MEMBERSHIP': idTransaksiMembership,
        if (idMasterMembership != null) 'ID_MASTER_MEMBERSHIP': idMasterMembership,
        if (nikCustomer != null) 'NIK_CUSTOMER': nikCustomer,
      };
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}update_member_status.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      if (response.statusCode != 200) {
        throw Exception('Gagal update status member: HTTP ${response.statusCode}');
      }
      final data = json.decode(response.body);
      if (data['error'] != null) {
        throw Exception(data['error']);
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Nonaktifkan customer aktif berdasarkan ID transaksi terakhir
  Future<void> deactivateCustomer({
    required String idTransaksiMembership,
  }) async {
    await updateMemberStatus(idTransaksiMembership: idTransaksiMembership, status: 0);
  }

  Future<void> deleteMembership(String id) async {
    try {
      print("Fetch URL: ${AppConfig.baseUrl}delete_membership.php");
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}delete_membership.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'ID_MASTER_MEMBERSHIP': id}),
      );
      if (response.statusCode != 200) {
        throw Exception('Gagal menghapus membership: HTTP ${response.statusCode}');
      }
      final data = json.decode(response.body);
      if (data['error'] != null) {
        throw Exception(data['error']);
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Hapus customer dari master membership (unassign semua transaksi untuk pasangan master+nik)
  Future<void> removeMemberFromMaster({
    required String idMasterMembership,
    required String nikCustomer,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}remove_member_from_membership.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'ID_MASTER_MEMBERSHIP': idMasterMembership,
          'NIK_CUSTOMER': nikCustomer,
        }),
      );
      if (response.statusCode != 200) {
        throw Exception('Gagal menghapus customer dari membership: HTTP ${response.statusCode}');
      }
      final data = json.decode(response.body);
      if (data is Map && data['status'] != 'success') {
        final msg = data['message']?.toString() ?? 'Gagal menghapus customer dari membership';
        throw Exception(msg);
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}
