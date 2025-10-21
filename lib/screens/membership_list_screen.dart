import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:sia_mobile_soosvaldo/utils/rupiah_input_formatter.dart';
import 'package:sia_mobile_soosvaldo/models/membership_model.dart';
import 'package:sia_mobile_soosvaldo/models/membership_detail_model.dart';
import 'package:sia_mobile_soosvaldo/services/membership_service.dart';
import 'package:sia_mobile_soosvaldo/models/customer_model.dart';
import 'package:sia_mobile_soosvaldo/services/customer_service.dart';
import 'package:sia_mobile_soosvaldo/widgets/membership_badge.dart';

class MembershipListScreen extends StatefulWidget {
  const MembershipListScreen({super.key});

  @override
  MembershipListScreenState createState() => MembershipListScreenState();
}

class MembershipListScreenState extends State<MembershipListScreen> {
  final MembershipService _service = MembershipService();
  final CustomerService _customerService = CustomerService();
  late Future<List<MembershipDetailModel>> _detailList;
  late Future<List<CustomerModel>> _customerList;

  @override
  void initState() {
    super.initState();
    _detailList = _service.getMembershipDetails();
    _customerList = _customerService.getCustomers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Membership')),
      body: FutureBuilder<List<MembershipDetailModel>>(
        future: _detailList,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.isEmpty) {
              return const Center(child: Text('Belum ada data'));
            }
            final items = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    'Guide: Potongan membership umumnya <=5% (Silver), <=10% (Gold), <=15% (Ruby). Potongan diterapkan otomatis saat transaksi POS ketika customer aktif.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 4),
                ...items.map((master) {
                  final isReady = master.status == 1;
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: ExpansionTile(
                      // Hilangkan garis divider default di Material 3
                      shape: RoundedRectangleBorder(
                        side: BorderSide.none,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      collapsedShape: RoundedRectangleBorder(
                        side: BorderSide.none,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      title: Text(master.namaMembership),
                      subtitle: Text('Harga: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(master.hargaMembership)} | Potongan: ${master.potongan}%'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MembershipBadge(name: master.namaMembership, percent: master.potongan),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showEditDialogFromDetail(master),
                            tooltip: 'Edit Master',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            tooltip: 'Hapus Master',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                                  contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                                  actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  title: const Text('Konfirmasi Hapus'),
                                  content: Text('Hapus membership "${master.namaMembership}"?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                _deleteMembership(master.idMasterMembership);
                              }
                            },
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: ElevatedButton.icon(
                              onPressed: () => _showAddCustomerDialog(master),
                              icon: const Icon(Icons.person_add),
                              label: const Text('+ Add Customer'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...master.customers.map((c) {
                          final active = c.status == 1;
                          final sisaText = c.sisaHari != null && c.sisaHari! > 0
                              ? '${c.sisaHari} hari lagi'
                              : (c.timestampHabis != null ? 'Kadaluarsa' : 'Belum ada transaksi');
                          return ListTile(
                            title: Text('${c.namaCustomer} (${c.nikCustomer})'),
                            subtitle: Text('Masa aktif: $sisaText'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: active,
                                  onChanged: (v) => _toggleCustomer(master, c, v),
                                ),
                                if (!active) ...[
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () => _removeCustomerFromMaster(master, c),
                                    child: const Text('Hapus'),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                }).toList(),
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

  void _showAddDialog() async {
    final customers = await _customerList;
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => MembershipFormDialog(customers: customers, onSubmit: _addMembership),
    );
  }

  void _showEditDialogFromDetail(MembershipDetailModel membership) async {
    final customers = await _customerList;
    if (!mounted) return;
    
    // Konversi ke MembershipModel untuk dialog
    final membershipModel = MembershipModel(
      idMasterMembership: membership.idMasterMembership,
      nikKaryawan: '',
      namaMembership: membership.namaMembership,
      hargaMembership: membership.hargaMembership,
      potongan: membership.potongan,
      status: membership.status,
    );
    
    showDialog(
      context: context,
      builder: (context) => MembershipFormDialog(
        membership: membershipModel, 
        customers: customers, 
        onSubmit: (updatedMembership) => _updateMembership(updatedMembership, null),
        onBulkAssign: (template, nikList) => _bulkAssignMembership(template, nikList),
      ),
    );
  }

  Future<void> _bulkAssignMembership(MembershipModel template, List<String> nikList) async {
    try {
      // Gunakan endpoint baru untuk assign banyak customer ke satu master
      await _service.addMembersToMaster(
        idMasterMembership: template.idMasterMembership,
        nikCustomers: nikList,
      );
      if (!mounted) return;
      setState(() {
        _detailList = _service.getMembershipDetails();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Berhasil assign membership ke ${nikList.length} customer')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _addMembership(MembershipModel membership) async {
    try {
      await _service.addMembership(membership);
      if (!mounted) return;
      setState(() {
        _detailList = _service.getMembershipDetails();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _updateMembership(MembershipModel membership, MembershipDetailModel? originalMembership) async {
    try {
      // Per arsitektur baru: update master saja; transaksi/jurnal dilakukan via assign terpisah
      await _service.updateMembership(membership);

      if (!mounted) return;
      setState(() {
        _detailList = _service.getMembershipDetails();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _deleteMembership(String id) async {
    try {
      await _service.deleteMembership(id);
      if (!mounted) return;
      setState(() {
        _detailList = _service.getMembershipDetails();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // Dialog untuk assign customer baru ke master membership
  Future<void> _showAddCustomerDialog(MembershipDetailModel master) async {
    final customers = await _customerList;
    final details = await _detailList;
    if (!mounted) return;
    // Exclude customer yang sudah terassign di membership manapun (lintas tipe)
    final assignedNik = details
        .expand((m) => m.customers.map((e) => e.nikCustomer))
        .toSet();
    final options = customers.where((c) => !assignedNik.contains(c.nikCustomer)).toList();
    final selected = <String>{};
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text('+ Add Customer ke ${master.namaMembership}'),
          content: SizedBox(
            width: 420,
            child: StatefulBuilder(
              builder: (context, setInnerState) {
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, i) {
                    final c = options[i];
                    final nik = c.nikCustomer.toString();
                    final checked = selected.contains(nik);
                    return CheckboxListTile(
                      value: checked,
                      onChanged: (v) {
                        setInnerState(() {
                          if (v == true) {
                            selected.add(nik);
                          } else {
                            selected.remove(nik);
                          }
                        });
                      },
                      title: Text('${c.nikCustomer} - ${c.namaCustomer}'),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            TextButton(
              onPressed: () async {
                if (selected.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih minimal satu customer')));
                  return;
                }
                try {
                  await _service.addMembersToMaster(
                    idMasterMembership: master.idMasterMembership,
                    nikCustomers: selected.toList(),
                  );
                  if (!mounted) return;
                  Navigator.pop(context);
                  setState(() {
                    _detailList = _service.getMembershipDetails();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Berhasil assign ke ${selected.length} customer')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );
  }

  // Reaktivasi/perpanjang untuk satu customer dengan validasi tidak boleh masih aktif
  Future<void> _reactivateCustomer(MembershipDetailModel master, MemberEntry entry) async {
    final isActive = entry.status == 1 && (entry.sisaHari ?? 0) > 0;
    if (isActive) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer masih memiliki membership aktif')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: const Text('Konfirmasi Reaktivasi'),
        content: Text('Perpanjang Membership untuk ${entry.namaCustomer} (${entry.nikCustomer})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya')), 
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _service.reactivateCustomer(
        idMasterMembership: master.idMasterMembership,
        nikCustomer: entry.nikCustomer,
      );
      if (!mounted) return;
      setState(() {
        _detailList = _service.getMembershipDetails();
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reaktivasi berhasil')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // Toggle aktif/nonaktif dengan konfirmasi sebelum eksekusi
  Future<void> _toggleCustomer(MembershipDetailModel master, MemberEntry entry, bool targetActive) async {
    final actionText = targetActive ? 'mengaktifkan kembali' : 'menonaktifkan';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: const Text('Konfirmasi'),
        content: Text('Yakin ingin $actionText membership untuk ${entry.namaCustomer} (${entry.nikCustomer})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _service.updateMemberStatus(
        idMasterMembership: master.idMasterMembership,
        nikCustomer: entry.nikCustomer,
        status: targetActive ? 1 : 0,
      );
      if (!mounted) return;
      setState(() {
        _detailList = _service.getMembershipDetails();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(targetActive ? 'Customer diaktifkan' : 'Customer dinonaktifkan')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _removeCustomerFromMaster(MembershipDetailModel master, MemberEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: const Text('Hapus dari membership'),
        content: Text('Hapus ${entry.namaCustomer} (${entry.nikCustomer}) dari ${master.namaMembership}?\n\nCatatan: Ini berguna jika ingin pindah ke membership lain. Riwayat transaksi membership pada master ini akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _service.removeMemberFromMaster(
        idMasterMembership: master.idMasterMembership,
        nikCustomer: entry.nikCustomer,
      );
      if (!mounted) return;
      setState(() {
        _detailList = _service.getMembershipDetails();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer dihapus dari membership')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

class MembershipFormDialog extends StatefulWidget {
  final MembershipModel? membership;
  final List<CustomerModel> customers;
  final Function(MembershipModel) onSubmit;
  final Function(MembershipModel, List<String>)? onBulkAssign;
  const MembershipFormDialog({super.key, this.membership, required this.customers, required this.onSubmit, this.onBulkAssign});
  @override
  MembershipFormDialogState createState() => MembershipFormDialogState();
}

class MembershipFormDialogState extends State<MembershipFormDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _idMasterMembership;
  late String _nikKaryawan;
  late String _namaMembership;
  late double _hargaMembership;
  late int _potongan;
  late int _status;
  bool _multiAssignEnabled = false;
  final List<String> _selectedNikCustomers = [];

  @override
  void initState() {
    super.initState();
    _idMasterMembership = widget.membership?.idMasterMembership;
    // Add (master-only) tidak membutuhkan NIK; pada edit bisa diisi jika diperlukan untuk aksi lain
    _nikKaryawan = widget.membership?.nikKaryawan ?? '';
    _namaMembership = widget.membership?.namaMembership ?? '';
    _hargaMembership = widget.membership?.hargaMembership ?? 0.0;
    _potongan = widget.membership?.potongan ?? 0;
    _status = widget.membership?.status ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.membership != null;
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Text(isEdit ? 'Edit: ${_namaMembership.isNotEmpty ? _namaMembership : 'Membership'}' : 'Add Membership'),
      content: SizedBox(
        width: math.min(420.0, MediaQuery.of(context).size.width * 0.9),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Edit master membership tidak menampilkan NIK atau multi-assign.
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nama Membership', hintText: 'Masukkan nama membership'),
                initialValue: isEdit ? _namaMembership : null,
                validator: (value) => value == null || value.isEmpty ? 'Nama membership wajib diisi' : null,
                onChanged: (value) => _namaMembership = value,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Harga Membership',
                  hintText: 'Masukkan harga membership',
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  ThousandsSeparatorInputFormatter(),
                ],
                initialValue: isEdit ? NumberFormat('#,##0').format(_hargaMembership) : null,
                validator: (value) => value == null || value.isEmpty ? 'Harga wajib diisi' : null,
                onChanged: (value) {
                  final raw = value.replaceAll('.', '');
                  _hargaMembership = double.tryParse(raw) ?? 0.0;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Potongan (%)', hintText: 'Masukkan potongan'),
                keyboardType: TextInputType.number,
                initialValue: isEdit ? _potongan.toString() : null,
                validator: (value) => value == null || value.isEmpty ? 'Potongan wajib diisi' : null,
                onChanged: (value) => _potongan = int.tryParse(value) ?? 0,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Ready')),
                  DropdownMenuItem(value: 0, child: Text('Tidak Ready')),
                ],
                onChanged: (value) => _status = value ?? 1,
              ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final membership = MembershipModel(
                idMasterMembership: _idMasterMembership ?? '',
                nikKaryawan: _nikKaryawan,
                namaMembership: _namaMembership,
                hargaMembership: _hargaMembership,
                potongan: _potongan,
                status: _status,
              );
              _confirmAndExecute(
                title: isEdit ? 'Konfirmasi Update' : 'Konfirmasi Add',
                message: () {
                  return 'Nama: ${_namaMembership}\nHarga: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(_hargaMembership)}\nPotongan: ${_potongan}%\nStatus: ${_status == 1 ? 'Ready' : 'Tidak Ready'}\nLanjut?';
                }(),
                onConfirmed: () {
                  widget.onSubmit(membership);
                  Navigator.pop(context);
                },
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _openCustomerMultiSelect() {
    final options = widget.customers.map((c) => c.nikCustomer.toString()).toList();
    final selected = Set<String>.of(_selectedNikCustomers);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pilih Customer'),
          content: SizedBox(
            width: 400,
            child: StatefulBuilder(
              builder: (context, setInnerState) {
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final nik = options[index];
                    final customer = widget.customers.firstWhere((c) => c.nikCustomer.toString() == nik);
                    final checked = selected.contains(nik);
                    return CheckboxListTile(
                      value: checked,
                      onChanged: (v) {
                        setInnerState(() {
                          if (v == true) {
                            selected.add(nik);
                          } else {
                            selected.remove(nik);
                          }
                        });
                      },
                      title: Text('${customer.nikCustomer} - ${customer.namaCustomer}'),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedNikCustomers
                    ..clear()
                    ..addAll(selected);
                });
                Navigator.pop(context);
              },
              child: const Text('Pilih'),
            ),
          ],
        );
      },
    );
  }

  void _confirmAndExecute({required String title, required String message, required VoidCallback onConfirmed}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirmed();
              },
              child: const Text('Ya, lanjut'),
            ),
          ],
        );
      },
    );
  }
}