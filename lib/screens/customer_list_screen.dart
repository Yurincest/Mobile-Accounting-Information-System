import 'package:flutter/material.dart';
import 'package:sia_mobile_soosvaldo/models/customer_model.dart';
import 'package:sia_mobile_soosvaldo/services/customer_service.dart';
import 'package:sia_mobile_soosvaldo/services/membership_service.dart';
import 'package:sia_mobile_soosvaldo/models/membership_detail_model.dart';
import 'package:sia_mobile_soosvaldo/widgets/membership_badge.dart';

// Holder info untuk badge membership di CustomerList
class _MemberInfo {
  final String name;
  final int percent;
  const _MemberInfo(this.name, this.percent);
}

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  CustomerListScreenState createState() => CustomerListScreenState();
}

class CustomerListScreenState extends State<CustomerListScreen> {
  final CustomerService _service = CustomerService();
  final MembershipService _membershipService = MembershipService();
  late Future<List<CustomerModel>> _customerList;
  Map<String, _MemberInfo> _membershipByNik = {};
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _customerList = _service.getCustomers();
    // Load membership details to map customer -> (membership name, discount)
    _membershipService.getMembershipDetails().then((details) {
      final map = <String, _MemberInfo>{};
      for (final m in details) {
        for (final c in m.customers) {
          // Assume one membership per customer across masters
          map[c.nikCustomer] = _MemberInfo(m.namaMembership, m.potongan);
        }
      }
      if (!mounted) return;
      setState(() {
        _membershipByNik = map;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer')),
      body: FutureBuilder<List<CustomerModel>>(
        future: _customerList,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.isEmpty) {
              return const Center(child: Text('Belum ada data'));
            }
            var data = snapshot.data!;
            if (_searchQuery.isNotEmpty) {
              final q = _searchQuery.toLowerCase().trim();
              data = data.where((c) =>
                c.namaCustomer.toLowerCase().contains(q) ||
                c.email.toLowerCase().contains(q) ||
                c.nikCustomer.toLowerCase().contains(q)
              ).toList();
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Cari customer (nama / email / NIK)',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final customer = data[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          title: Text(customer.namaCustomer),
                          subtitle: Text(customer.email),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_membershipByNik.containsKey(customer.nikCustomer)) ...[
                                MembershipBadge(
                                  name: _membershipByNik[customer.nikCustomer]!.name,
                                  percent: _membershipByNik[customer.nikCustomer]!.percent,
                                ),
                                const SizedBox(width: 8),
                              ],
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditDialog(customer),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _confirmDeleteCustomer(customer.nikCustomer),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomerFormDialog(onSubmit: _addCustomer),
    );
  }

  void _showEditDialog(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => CustomerFormDialog(customer: customer, onSubmit: _updateCustomer),
    );
  }

  void _addCustomer(CustomerModel customer) async {
    try {
      await _service.addCustomer(customer);
      if (!mounted) return;
      setState(() {
        _customerList = _service.getCustomers();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _updateCustomer(CustomerModel customer) async {
    try {
      await _service.updateCustomer(customer);
      if (!mounted) return;
      setState(() {
        _customerList = _service.getCustomers();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _deleteCustomer(String nik) async {
    try {
      await _service.deleteCustomer(nik);
      if (!mounted) return;
      setState(() {
        _customerList = _service.getCustomers();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _confirmDeleteCustomer(String nik) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: const Text('Konfirmasi Hapus'),
          content: Text('Yakin ingin menghapus customer dengan NIK $nik?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                _deleteCustomer(nik);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }
}

class CustomerFormDialog extends StatefulWidget {
  final CustomerModel? customer;
  final Function(CustomerModel) onSubmit;

  const CustomerFormDialog({super.key, this.customer, required this.onSubmit});

  @override
  CustomerFormDialogState createState() => CustomerFormDialogState();
}

class CustomerFormDialogState extends State<CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _nik;
  late String _nama;
  late String _email;

  @override
  void initState() {
    super.initState();
    _nik = widget.customer?.nikCustomer ?? '';
    _nama = widget.customer?.namaCustomer ?? '';
    _email = widget.customer?.email ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Text(widget.customer == null ? 'Add Customer' : 'Edit Customer'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'NIK (manual)', hintText: 'Masukkan NIK'),
                keyboardType: TextInputType.text,
                initialValue: widget.customer != null ? _nik : null,
                validator: (value) => value!.isEmpty ? 'NIK is required' : null,
                onChanged: (value) => _nik = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nama', hintText: 'Masukkan nama'),
                initialValue: widget.customer != null ? _nama : null,
                validator: (value) => value!.isEmpty ? 'Nama is required' : null,
                onChanged: (value) => _nama = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email', hintText: 'Masukkan email'),
                initialValue: widget.customer != null ? _email : null,
                validator: (value) => value!.isEmpty ? 'Email is required' : null,
                onChanged: (value) => _email = value,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final originalNik = widget.customer?.nikCustomer;
              final isNikChanged = originalNik != null && _nik != originalNik;

              bool proceed = true;
              if (isNikChanged) {
                proceed = (await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        title: const Text('Konfirmasi Perubahan NIK'),
                        content: Text(
                            'Anda mengubah NIK dari $originalNik menjadi $_nik. Perubahan NIK dapat berdampak pada data terkait. Lanjutkan menyimpan?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Lanjutkan'),
                          ),
                        ],
                      ),
                    )) ??
                    false;
              }

              if (!proceed) {
                // Jika batal, kembalikan ke NIK asli
                setState(() => _nik = originalNik ?? _nik);
                return;
              }

              final customer = CustomerModel(
                nikCustomer: _nik,
                namaCustomer: _nama,
                email: _email,
              );
              widget.onSubmit(customer);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}