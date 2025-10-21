import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sia_mobile_soosvaldo/app_config.dart';
import 'package:sia_mobile_soosvaldo/models/customer_model.dart';

class CustomerService {
  Future<List<CustomerModel>> getCustomers() async {
    try {
      print("Fetch URL: ${AppConfig.baseUrl}get_customer.php");
      final uri = Uri.parse('${AppConfig.baseUrl}get_customer.php').replace(
        queryParameters: {'_ts': DateTime.now().millisecondsSinceEpoch.toString()},
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Non-200 from get_customer.php: ${response.statusCode} body: $snippet');
        throw Exception('Gagal memuat customer: HTTP ${response.statusCode}');
      }
      try {
        print('Headers: ${response.headers}');
        print('Raw body >>>${response.body}<<<');
        final jsonResponse = json.decode(response.body);
        if (jsonResponse is Map && jsonResponse['status'] == 'error') {
          final msg = jsonResponse['message']?.toString() ?? 'Server error saat memuat customer';
          if (msg.toLowerCase().contains('belum ada data')) return <CustomerModel>[];
          throw Exception(msg);
        }
        final List<dynamic> dynamicList =
            jsonResponse is List ? jsonResponse : (jsonResponse is Map && jsonResponse['data'] is List ? jsonResponse['data'] : []);
        return dynamicList.map((item) => CustomerModel.fromJson(item)).toList();
      } catch (e) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Invalid JSON from get_customer.php: $snippet');
        throw Exception('Respon server tidak valid saat memuat customer');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> addCustomer(CustomerModel customer) async {
    try {
      print("Fetch URL: ${AppConfig.baseUrl}add_customer.php");
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}add_customer.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(customer.toJson()),
      );
      if (response.statusCode != 200) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Non-200 from add_customer.php: ${response.statusCode} body: $snippet');
        throw Exception('Gagal menambah customer: HTTP ${response.statusCode}');
      }
      try {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse is Map && jsonResponse['status'] != 'success') {
          throw Exception(jsonResponse['message']?.toString() ?? 'Gagal menambah customer');
        }
      } catch (e) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Invalid JSON from add_customer.php: $snippet');
        throw Exception('Respon server tidak valid saat menambah customer');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    try {
      print("Fetch URL: ${AppConfig.baseUrl}update_customer.php");
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}update_customer.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(customer.toJson()),
      );
      if (response.statusCode != 200) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Non-200 from update_customer.php: ${response.statusCode} body: $snippet');
        throw Exception('Gagal memperbarui customer: HTTP ${response.statusCode}');
      }
      try {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse is Map && jsonResponse['status'] != 'success') {
          throw Exception(jsonResponse['message']?.toString() ?? 'Gagal memperbarui customer');
        }
      } catch (e) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Invalid JSON from update_customer.php: $snippet');
        throw Exception('Respon server tidak valid saat memperbarui customer');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> deleteCustomer(String nik) async {
    try {
      print("Fetch URL: ${AppConfig.baseUrl}delete_customer.php");
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}delete_customer.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'NIK_CUSTOMER': nik}),
      );
      if (response.statusCode != 200) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Non-200 from delete_customer.php: ${response.statusCode} body: $snippet');
        throw Exception('Gagal menghapus customer: HTTP ${response.statusCode}');
      }
      try {
        final data = json.decode(response.body);
        if (data is Map && data['status'] != 'success') {
          throw Exception(data['message']?.toString() ?? 'Gagal menghapus customer');
        }
      } catch (e) {
        final snippet = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        print('Invalid JSON from delete_customer.php: $snippet');
        throw Exception('Respon server tidak valid saat menghapus customer');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}

// Hapus cleaning manual: parsing harus pakai body penuh tanpa trim/split