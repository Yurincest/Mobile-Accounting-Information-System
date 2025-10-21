import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:sia_mobile_soosvaldo/utils/rupiah_input_formatter.dart';
import 'package:sia_mobile_soosvaldo/models/barang_model.dart';
import 'package:sia_mobile_soosvaldo/services/barang_service.dart';

class BarangListScreen extends StatefulWidget {
  const BarangListScreen({super.key});

  @override
  BarangListScreenState createState() => BarangListScreenState();
}

class BarangListScreenState extends State<BarangListScreen> {
  final BarangService _service = BarangService();
  late Future<List<BarangModel>> _barangList;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _barangList = _service.getBarang();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Barang')),
      body: FutureBuilder<List<BarangModel>>(
        future: _barangList,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.isEmpty) {
              return const Center(child: Text('Belum ada data'));
            }
            var data = snapshot.data!;
            if (_searchQuery.isNotEmpty) {
              final q = _searchQuery.toLowerCase().trim();
              data = data.where((b) =>
                b.namaBarang.toLowerCase().contains(q) ||
                b.kodeBarang.toLowerCase().contains(q)
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
                      hintText: 'Cari barang (Nama / Kode)',
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
                      final barang = data[index];
                      final isReady = barang.status == 1;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          title: Text(barang.namaBarang),
                          subtitle: Text('Harga: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(barang.hargaBarang)} | Stok: ${barang.stokBarang}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isReady ? Colors.green.shade100 : Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isReady ? Colors.green : Colors.red),
                                ),
                                child: Text(isReady ? 'Ready' : 'Tidak Ready',
                                    style: TextStyle(color: isReady ? Colors.green.shade800 : Colors.red.shade800)),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditDialog(barang),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _confirmDeleteBarang(barang.kodeBarang),
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
      builder: (context) => BarangFormDialog(onSubmit: _addBarang),
    );
  }

  void _showEditDialog(BarangModel barang) {
    showDialog(
      context: context,
      builder: (context) => BarangFormDialog(barang: barang, onSubmit: _updateBarang),
    );
  }

  void _addBarang(BarangModel barang) async {
    try {
      await _service.addBarang(barang);
      if (!mounted) return;
      setState(() {
        _barangList = _service.getBarang();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _updateBarang(BarangModel barang) async {
    try {
      await _service.updateBarang(barang);
      if (!mounted) return;
      setState(() {
        _barangList = _service.getBarang();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _deleteBarang(String kode) async {
    try {
      await _service.deleteBarang(kode);
      if (!mounted) return;
      setState(() {
        _barangList = _service.getBarang();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _confirmDeleteBarang(String kode) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: const Text('Konfirmasi Hapus'),
          content: Text('Yakin ingin menghapus barang dengan kode $kode?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                _deleteBarang(kode);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }
}

class BarangFormDialog extends StatefulWidget {
  final BarangModel? barang;
  final Function(BarangModel) onSubmit;

  const BarangFormDialog({super.key, this.barang, required this.onSubmit});

  @override
  BarangFormDialogState createState() => BarangFormDialogState();
}

class BarangFormDialogState extends State<BarangFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _kode;
  late String _nama;
  late double _harga;
  late int _stok;
  late int _status;

  @override
  void initState() {
    super.initState();
    _kode = widget.barang?.kodeBarang ?? '';
    _nama = widget.barang?.namaBarang ?? '';
    _harga = widget.barang?.hargaBarang ?? 0.0;
    _stok = widget.barang?.stokBarang ?? 0;
    _status = widget.barang?.status ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.barang != null;
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Text(isEdit ? 'Edit Barang' : 'Add Barang'),
      content: SizedBox(
        width: math.min(420.0, MediaQuery.of(context).size.width * 0.9),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              if (isEdit)
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Kode Barang (generated)'),
                  initialValue: _kode,
                  readOnly: true,
                ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nama Barang', hintText: 'Masukkan nama barang'),
                initialValue: isEdit ? _nama : null,
                validator: (value) => value!.isEmpty ? 'Nama is required' : null,
                onChanged: (value) => _nama = value,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Harga Barang',
                  hintText: 'Masukkan harga',
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  ThousandsSeparatorInputFormatter(),
                ],
                initialValue: isEdit ? NumberFormat('#,##0').format(_harga) : null,
                validator: (value) => value!.isEmpty ? 'Harga is required' : null,
                onChanged: (value) {
                  final raw = value.replaceAll('.', '');
                  _harga = double.tryParse(raw) ?? 0.0;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Stok Barang', hintText: 'Masukkan stok'),
                keyboardType: TextInputType.number,
                initialValue: isEdit ? _stok.toString() : null,
                validator: (value) => value!.isEmpty ? 'Stok is required' : null,
                onChanged: (value) => _stok = int.tryParse(value) ?? 0,
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
              final barang = BarangModel(
                kodeBarang: _kode,
                namaBarang: _nama,
                hargaBarang: _harga,
                stokBarang: _stok,
                status: _status,
              );
              widget.onSubmit(barang);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}