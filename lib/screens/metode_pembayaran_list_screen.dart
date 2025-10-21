import 'package:flutter/material.dart';
import 'package:sia_mobile_soosvaldo/models/metode_pembayaran_model.dart';
import 'package:sia_mobile_soosvaldo/services/metode_pembayaran_service.dart';

class MetodePembayaranListScreen extends StatefulWidget {
  const MetodePembayaranListScreen({super.key});

  @override
  MetodePembayaranListScreenState createState() => MetodePembayaranListScreenState();
}

class MetodePembayaranListScreenState extends State<MetodePembayaranListScreen> {
  final MetodePembayaranService _service = MetodePembayaranService();
  late Future<List<MetodePembayaranModel>> _metodeList;

  @override
  void initState() {
    super.initState();
    _metodeList = _service.getMetodePembayaran();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Metode Pembayaran')),
      body: FutureBuilder<List<MetodePembayaranModel>>(
        future: _metodeList,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.isEmpty) {
              return const Center(child: Text('Belum ada data'));
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final metode = snapshot.data![index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    title: Text(metode.namaMetode),
                    subtitle: Text('Kode: ${metode.kodeMetode}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditDialog(metode),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteMetode(metode.kodeMetode),
                        ),
                      ],
                    ),
                  ),
                );
              },
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
      builder: (context) => MetodePembayaranFormDialog(onSubmit: _addMetode),
    );
  }

  void _showEditDialog(MetodePembayaranModel metode) {
    showDialog(
      context: context,
      builder: (context) => MetodePembayaranFormDialog(metode: metode, onSubmit: _updateMetode),
    );
  }

  void _addMetode(MetodePembayaranModel metode) async {
    try {
      await _service.addMetodePembayaran(metode);
      if (!mounted) return;
      setState(() {
        _metodeList = _service.getMetodePembayaran();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _updateMetode(MetodePembayaranModel metode) async {
    try {
      await _service.updateMetodePembayaran(metode);
      if (!mounted) return;
      setState(() {
        _metodeList = _service.getMetodePembayaran();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _deleteMetode(String kode) async {
    try {
      await _service.deleteMetodePembayaran(kode);
      if (!mounted) return;
      setState(() {
        _metodeList = _service.getMetodePembayaran();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

class MetodePembayaranFormDialog extends StatefulWidget {
  final MetodePembayaranModel? metode;
  final Function(MetodePembayaranModel) onSubmit;

  const MetodePembayaranFormDialog({super.key, this.metode, required this.onSubmit});

  @override
  MetodePembayaranFormDialogState createState() => MetodePembayaranFormDialogState();
}

class MetodePembayaranFormDialogState extends State<MetodePembayaranFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _kode;
  late String _nama;
  late int _status;

  @override
  void initState() {
    super.initState();
    _kode = widget.metode?.kodeMetode ?? '';
    _nama = widget.metode?.namaMetode ?? '';
    _status = widget.metode?.status ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.metode != null;
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Text(isEdit ? 'Edit Metode Pembayaran' : 'Add Metode Pembayaran'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Kode Metode', hintText: 'Masukkan kode metode'),
              initialValue: _kode,
              readOnly: isEdit,
              validator: (value) => value!.isEmpty ? 'Kode is required' : null,
              onChanged: (value) => _kode = value,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Nama Metode', hintText: 'Masukkan nama metode'),
              initialValue: _nama,
              validator: (value) => value!.isEmpty ? 'Nama is required' : null,
              onChanged: (value) => _nama = value,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Status (1/0)', hintText: 'Masukkan status (1 atau 0)'),
              keyboardType: TextInputType.number,
              initialValue: _status.toString(),
              validator: (value) => value!.isEmpty || (int.tryParse(value) != 0 && int.tryParse(value) != 1) ? 'Status must be 0 or 1' : null,
              onChanged: (value) => _status = int.tryParse(value) ?? 1,
            ),
          ],
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
              final metode = MetodePembayaranModel(
                kodeMetode: _kode,
                namaMetode: _nama,
                status: _status,
              );
              widget.onSubmit(metode);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}