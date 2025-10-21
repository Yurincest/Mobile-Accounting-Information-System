import 'package:flutter/material.dart';
import 'package:sia_mobile_soosvaldo/models/karyawan_model.dart';
import 'package:sia_mobile_soosvaldo/services/karyawan_service.dart';

class KaryawanListScreen extends StatefulWidget {
  const KaryawanListScreen({super.key});

  @override
  KaryawanListScreenState createState() => KaryawanListScreenState();
}

class KaryawanListScreenState extends State<KaryawanListScreen> {
  final KaryawanService _service = KaryawanService();
  late Future<List<KaryawanModel>> _karyawanList;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _karyawanList = _service.getKaryawan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Karyawan')),
      body: FutureBuilder<List<KaryawanModel>>(
        future: _karyawanList,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.isEmpty) {
              return const Center(child: Text('Belum ada data'));
            }
            // Filter in-memory berdasarkan query
            var data = snapshot.data!;
            if (_searchQuery.isNotEmpty) {
              final q = _searchQuery.toLowerCase().trim();
              data = data.where((k) =>
                k.namaKaryawan.toLowerCase().contains(q) ||
                k.email.toLowerCase().contains(q) ||
                k.nikKaryawan.toLowerCase().contains(q)
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
                      hintText: 'Cari karyawan (nama / email / NIK)',
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
                      final karyawan = data[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          title: Text(karyawan.namaKaryawan),
                          subtitle: Text(karyawan.email),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditDialog(karyawan),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _confirmDeleteKaryawan(karyawan.nikKaryawan),
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
      builder: (context) => KaryawanFormDialog(onSubmit: _addKaryawan),
    );
  }

  void _showEditDialog(KaryawanModel karyawan) {
    showDialog(
      context: context,
      builder: (context) => KaryawanFormDialog(karyawan: karyawan, onSubmit: _updateKaryawan),
    );
  }

  void _addKaryawan(KaryawanModel karyawan) async {
    try {
      await _service.addKaryawan(karyawan);
      if (!mounted) return;
      setState(() {
        _karyawanList = _service.getKaryawan();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _updateKaryawan(KaryawanModel karyawan) async {
    try {
      await _service.updateKaryawan(karyawan);
      if (!mounted) return;
      setState(() {
        _karyawanList = _service.getKaryawan();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _deleteKaryawan(String nik) async {
    try {
      await _service.deleteKaryawan(nik);
      if (!mounted) return;
      setState(() {
        _karyawanList = _service.getKaryawan();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _confirmDeleteKaryawan(String nik) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: const Text('Konfirmasi Hapus'),
          content: Text('Yakin ingin menghapus karyawan dengan NIK $nik?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                _deleteKaryawan(nik);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }
}

class KaryawanFormDialog extends StatefulWidget {
  final KaryawanModel? karyawan;
  final Function(KaryawanModel) onSubmit;

  const KaryawanFormDialog({super.key, this.karyawan, required this.onSubmit});

  @override
  KaryawanFormDialogState createState() => KaryawanFormDialogState();
}

class KaryawanFormDialogState extends State<KaryawanFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _nik;
  late String _nama;
  late String _email;
  late String _password;

  @override
  void initState() {
    super.initState();
    _nik = widget.karyawan?.nikKaryawan ?? '';
    _nama = widget.karyawan?.namaKaryawan ?? '';
    _email = widget.karyawan?.email ?? '';
    _password = widget.karyawan?.password ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Text(widget.karyawan == null ? 'Add Karyawan' : 'Edit Karyawan'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'NIK (manual)', hintText: 'Masukkan NIK'),
                keyboardType: TextInputType.text,
                initialValue: widget.karyawan != null ? _nik : null,
                validator: (value) => value!.isEmpty ? 'NIK is required' : null,
                onChanged: (value) => _nik = value,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nama', hintText: 'Masukkan nama'),
                initialValue: widget.karyawan != null ? _nama : null,
                validator: (value) => value!.isEmpty ? 'Nama is required' : null,
                onChanged: (value) => _nama = value,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email', hintText: 'Masukkan email'),
                initialValue: widget.karyawan != null ? _email : null,
                validator: (value) => value!.isEmpty ? 'Email is required' : null,
                onChanged: (value) => _email = value,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password', hintText: 'Masukkan password'),
                obscureText: true,
                initialValue: widget.karyawan != null ? _password : null,
                validator: (value) => value!.isEmpty ? 'Password is required' : null,
                onChanged: (value) => _password = value,
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
              final originalNik = widget.karyawan?.nikKaryawan;
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

              final karyawan = KaryawanModel(
                nikKaryawan: _nik,
                namaKaryawan: _nama,
                email: _email,
                password: _password,
              );
              widget.onSubmit(karyawan);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}