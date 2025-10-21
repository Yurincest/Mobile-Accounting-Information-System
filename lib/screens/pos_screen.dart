import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:sia_mobile_soosvaldo/utils/rupiah_input_formatter.dart';
import 'package:sia_mobile_soosvaldo/models/barang_model.dart';
import 'package:sia_mobile_soosvaldo/models/customer_model.dart';
import 'package:sia_mobile_soosvaldo/models/metode_pembayaran_model.dart';
import 'package:sia_mobile_soosvaldo/services/barang_service.dart';
import 'package:sia_mobile_soosvaldo/services/customer_service.dart';
import 'package:sia_mobile_soosvaldo/services/metode_pembayaran_service.dart';
import 'package:sia_mobile_soosvaldo/services/pos_service.dart';
import 'package:sia_mobile_soosvaldo/models/transaksi_membership_model.dart';
import 'package:sia_mobile_soosvaldo/services/transaksi_membership_service.dart';
import 'package:sia_mobile_soosvaldo/app_config.dart';
import 'package:sia_mobile_soosvaldo/theme.dart';
import 'package:sia_mobile_soosvaldo/widgets/membership_badge.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  PosScreenState createState() => PosScreenState();
}

class PosScreenState extends State<PosScreen> {
  final PosService _posService = PosService();
  final CustomerService _customerService = CustomerService();
  final MetodePembayaranService _metodeService = MetodePembayaranService();
  final BarangService _barangService = BarangService();
  final TransaksiMembershipService _transaksiMembershipService =
      TransaksiMembershipService();

  late Future<List<CustomerModel>> _customers;
  late Future<List<MetodePembayaranModel>> _metodes;
  late Future<List<BarangModel>> _barangs;
  List<BarangModel>? _barangCache;

  String? _selectedCustomer;
  String? _selectedMetode;
  DateTime _tanggal = DateTime.now();
  final List<Map<String, dynamic>> _items = [];
  double _grossTotal = 0;
  double _total = 0;
  double _dp = 0;
  final int _status = 1;
  double _discountPercent = 0;
  double _discountAmount = 0;
  TransaksiMembershipModel? _activeMembership;
  bool _isCreditSelected = false;

  // Helper: seleksi customer dengan logika konsisten (konfirmasi bila ada item)
  Future<void> _selectCustomer(String nik) async {
    if (nik == _selectedCustomer) return;
    if (_items.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: const Text('Ubah Customer?'),
          content: const Text(
            'Mengubah customer akan menghapus barang yang sudah ditambahkan. Lanjutkan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ya'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
      setState(() {
        _items.clear();
        _grossTotal = 0;
        _discountAmount = 0;
        _total = 0;
        _dp = 0;
      });
    }
    // Set segera agar UI tidak menempel membership sebelumnya saat menunggu load
    setState(() {
      _selectedCustomer = nik;
      _activeMembership = null;
      _discountPercent = 0.0;
      _recalculateTotals();
    });
    await _loadActiveMembership(nik);
  }

  // Dialog pencarian customer
  Future<void> _showCustomerPickerDialog(List<CustomerModel> customers) async {
    final TextEditingController searchCtrl = TextEditingController();
    List<CustomerModel> filtered = List.of(customers);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: const Text('Pilih Customer'),
          content: SizedBox(
            width: 420,
            child: StatefulBuilder(
              builder: (context, setInnerState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchCtrl,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Cari nama / email / NIK',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) {
                        final q = v.toLowerCase().trim();
                        setInnerState(() {
                          filtered = customers
                              .where(
                                (c) =>
                                    c.namaCustomer.toLowerCase().contains(q) ||
                                    c.email.toLowerCase().contains(q) ||
                                    c.nikCustomer.toLowerCase().contains(q),
                              )
                              .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final c = filtered[i];
                          return ListTile(
                            title: Text(c.namaCustomer),
                            subtitle: Text('${c.nikCustomer} · ${c.email}'),
                            onTap: () async {
                              Navigator.pop(context);
                              await _selectCustomer(c.nikCustomer);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showQuickAddCustomerDialog();
              },
              child: const Text('+ Tambah Customer'),
            ),
          ],
        );
      },
    );
  }

  // Dialog tambah customer cepat
  Future<void> _showQuickAddCustomerDialog() async {
    final formKey = GlobalKey<FormState>();
    String nik = '';
    String nama = '';
    String email = '';
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Customer'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'NIK Customer'),
                  onChanged: (v) => nik = v.trim(),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'NIK wajib diisi'
                      : null,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nama Customer'),
                  onChanged: (v) => nama = v.trim(),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nama wajib diisi'
                      : null,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  onChanged: (v) => email = v.trim(),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Email wajib diisi'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                final newCustomer = CustomerModel(
                  nikCustomer: nik,
                  namaCustomer: nama,
                  email: email,
                );
                await _customerService.addCustomer(newCustomer);
                if (!mounted) return;
                // Refresh list
                setState(() {
                  _customers = _customerService.getCustomers();
                });
                Navigator.pop(context);
                await _selectCustomer(nik);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Customer berhasil ditambahkan'),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _customers = _customerService.getCustomers();
    _metodes = _metodeService.getMetodePembayaran();
    _barangs = _barangService.getBarang();
    _barangs.then((list) {
      if (!mounted) return;
      setState(() => _barangCache = list);
    });
  }

  void _addItem(BarangModel barang, int qty) {
    final double addSubtotal = barang.hargaBarang * qty;
    setState(() {
      // Cek jika item dengan kode yang sama sudah ada, lakukan merge qty
      final existingIndex = _items.indexWhere(
        (it) => it['KODE_BARANG'] == barang.kodeBarang,
      );
      if (existingIndex != -1) {
        _items[existingIndex]['QTY'] =
            (_items[existingIndex]['QTY'] as int) + qty;
        _items[existingIndex]['SUBTOTAL'] =
            (_items[existingIndex]['SUBTOTAL'] as double) + addSubtotal;
      } else {
        _items.add({
          'KODE_BARANG': barang.kodeBarang,
          'NAMA_BARANG': barang.namaBarang,
          'QTY': qty,
          'HARGA': barang.hargaBarang,
          'SUBTOTAL': addSubtotal,
        });
      }
      _grossTotal += addSubtotal;
      _recalculateTotals();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _grossTotal -= _items[index]['SUBTOTAL'];
      _items.removeAt(index);
      _recalculateTotals();
    });
  }

  void _recalculateTotals() {
    _discountAmount = _grossTotal * (_discountPercent / 100.0);
    _total = _grossTotal - _discountAmount; // Tidak ada pajak, fokus UI saja
    if (_total < 0) _total = 0;
  }

  Future<void> _loadActiveMembership(String nikCustomer) async {
    final membership = await _transaksiMembershipService.getActiveMembership(
      nikCustomer,
    );
    if (!mounted) return;
    setState(() {
      _activeMembership = membership;
      _discountPercent = membership?.potongan.toDouble() ?? 0.0;
      _recalculateTotals();
    });
  }

  bool _isSubmitting = false;
  void _submitTransaksi() async {
    if (_selectedCustomer == null || _selectedMetode == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Customer dan metode pembayaran wajib diisi')));
      return;
    }

    if (_items.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada barang ditambahkan')),
      );
      return;
    }

    if (_dp > _total) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('DP tidak boleh lebih besar dari total')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    Map<String, dynamic> data = {
      'NIK_CUSTOMER': _selectedCustomer,
      'NIK_KARYAWAN': AppConfig.nikKaryawan,
      'KODE_METODE': _selectedMetode,
      'TANGGAL': DateFormat('yyyy-MM-dd').format(_tanggal),
      'TOTAL': _total,
      'DP': _dp,
      'STATUS': _status,
      'DUE_DAYS': 60,
      'DETAIL_ITEMS': _items,
    };

    try {
      await _posService.addTransaksi(data);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Transaksi berhasil')));
      // Reset form
      setState(() {
        _items.clear();
        _grossTotal = 0;
        _discountAmount = 0;
        _total = 0;
        _dp = 0;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Point of Sale (POS)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<List<CustomerModel>>(
                    future: _customers,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        if (_selectedCustomer == null &&
                            snapshot.data!.isNotEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            _selectedCustomer = snapshot.data!.first.nikCustomer
                                .toString();
                            _loadActiveMembership(_selectedCustomer!);
                            setState(() {});
                          });
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Customer',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButton<String>(
                                    value: _selectedCustomer,
                                    hint: const Text('Pilih Customer'),
                                    items: snapshot.data!
                                        .map(
                                          (c) => DropdownMenuItem(
                                            value: c.nikCustomer.toString(),
                                            child: Text(c.namaCustomer),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) async {
                                      if (value == null) return;
                                      await _selectCustomer(value);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: 'Cari Customer',
                                  icon: const Icon(Icons.search),
                                  onPressed: () {
                                    final list = snapshot.data!;
                                    _showCustomerPickerDialog(list);
                                  },
                                ),
                                IconButton(
                                  tooltip: 'Tambah Customer',
                                  icon: const Icon(Icons.person_add_alt_1),
                                  onPressed: _showQuickAddCustomerDialog,
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                if (_activeMembership != null)
                                  MembershipBadge(
                                    name: _activeMembership!.namaMembership,
                                    percent: _activeMembership!.potongan,
                                    compact: true,
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF2F3F5),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(color: AppColors.textSecondary),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                                        SizedBox(width: 6),
                                        Text(
                                          'Belum Member',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (_activeMembership != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    'Potongan ${_activeMembership!.potongan}% · Habis ${_activeMembership!.timestampHabis}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error memuat customer: ${snapshot.error}',
                          ),
                        );
                      }
                      return const CircularProgressIndicator();
                    },
                  ),
                  FutureBuilder<List<MetodePembayaranModel>>(
                    future: _metodes,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        if (_selectedMetode == null &&
                            snapshot.data!.isNotEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            final first = snapshot.data!.first;
                            setState(() {
                              _selectedMetode = first.kodeMetode;
                              _isCreditSelected = _isCreditMethodName(
                                first.namaMetode,
                              );
                            });
                          });
                        }
                        if (snapshot.data!.isEmpty) {
                          return Column(
                            children: [
                              const Text('Belum ada metode pembayaran'),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  '/metode_pembayaran',
                                ),
                                child: const Text('Kelola Metode Pembayaran'),
                              ),
                            ],
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            const Text(
                              'Metode Pembayaran',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButton<String>(
                              value: _selectedMetode,
                              hint: const Text('Pilih Metode Pembayaran'),
                              items: snapshot.data!
                                  .map(
                                    (m) => DropdownMenuItem(
                                      value: m.kodeMetode,
                                      child: Text(m.namaMetode),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                final selected = snapshot.data!.firstWhere(
                                  (m) => m.kodeMetode == value,
                                );
                                setState(() {
                                  _selectedMetode = value;
                                  _isCreditSelected = _isCreditMethodName(
                                    selected.namaMetode,
                                  );
                                  if (!_isCreditSelected) {
                                    _dp =
                                        0; // reset DP jika bukan kredit/piutang
                                  }
                                });
                              },
                            ),
                          ],
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error memuat metode pembayaran: ${snapshot.error}',
                          ),
                        );
                      }
                      return const CircularProgressIndicator();
                    },
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    title: Text(
                      'Tanggal: ${DateFormat('dd/MM/yyyy').format(_tanggal)}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _tanggal,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (picked != null && mounted)
                        setState(() => _tanggal = picked);
                    },
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Items:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shrinkWrap: true,
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final kode = item['KODE_BARANG'] as String;
                      final stok = _barangCache?.firstWhere(
                            (b) => b.kodeBarang == kode,
                            orElse: () => BarangModel(
                              kodeBarang: kode,
                              namaBarang: item['NAMA_BARANG'] as String,
                              hargaBarang: item['HARGA'] as double,
                              stokBarang: 0,
                              status: 1,
                            ),
                          ).stokBarang ?? 0;
                      final qtyInCart = _cartQtyForKode(kode);
                      final sisa = (stok - qtyInCart).clamp(0, 1 << 30);
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        title: Text('Barang: ${item['NAMA_BARANG']}'),
                        subtitle: Text(
                          'Subtotal: ${_formatRupiah(item['SUBTOTAL'])} · Qty ${item['QTY']} · Sisa stok: $sisa',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: 'Edit Qty',
                              onPressed: () => _editItemQty(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _removeItem(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Subtotal: ${_formatRupiah(_grossTotal)}'),
                      Text(
                        'Diskon Member (${_discountPercent.toStringAsFixed(0)}%): -${_formatRupiah(_discountAmount)}',
                      ),
                      const Divider(),
                      Text('Total: ${_formatRupiah(_total)}'),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 16.0,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextFormField(
                        enabled: _isCreditSelected,
                        decoration: InputDecoration(
                          labelText: 'DP',
                          hintText: 'Masukkan DP',
                          prefixText: 'Rp ',
                          border: const OutlineInputBorder(),
                          helperText: _isCreditSelected
                              ? 'Opsional untuk transaksi Kredit/Piutang'
                              : 'DP hanya tersedia untuk metode Kredit/Piutang',
                          helperStyle: TextStyle(
                            color: _isCreditSelected ? AppColors.textSecondary : AppColors.warning,
                            fontWeight: _isCreditSelected ? FontWeight.w400 : FontWeight.w700,
                          ),
                          suffixIcon: _isCreditSelected
                              ? null
                              : const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          ThousandsSeparatorInputFormatter(),
                        ],
                        onChanged: (value) => setState(() {
                          final raw = value.replaceAll('.', '');
                          _dp = double.tryParse(raw) ?? 0;
                        }),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          label: 'Tambah Item',
                          icon: Icons.add,
                          onPressed: _showAddItemDialog,
                          variant: ButtonVariant.outline,
                          fullWidth: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CustomButton(
                    label: _isSubmitting ? 'Memproses...' : 'Submit Transaksi',
                    onPressed: _isSubmitting || !_formValid
                        ? null
                        : _submitTransaksi,
                    variant: ButtonVariant.filled,
                    fullWidth: true,
                    icon: Icons.check_circle_outline,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItemDialog() async {
    final barangs = await _barangs;
    if (!mounted) return;
    BarangModel? selectedBarang;
    int qty = 1;
    int sisaSaatIni() {
      if (selectedBarang == null) return 0;
      final inCart = _cartQtyForKode(selectedBarang!.kodeBarang);
      return (selectedBarang!.stokBarang - inCart).clamp(0, 1 << 30);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Item'),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        content: StatefulBuilder(
          builder: (ctx, setStateDialog) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<BarangModel>(
                decoration: const InputDecoration(
                  labelText: 'Pilih Barang',
                  hintText: 'Pilih barang',
                ),
                value: selectedBarang,
                items: barangs
                    .map(
                      (b) => DropdownMenuItem(value: b, child: Text(b.namaBarang)),
                    )
                    .toList(),
                onChanged: (value) => setStateDialog(() => selectedBarang = value),
              ),
              if (selectedBarang != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.sell_outlined, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text('Harga: ${_formatRupiah(selectedBarang!.hargaBarang)}',
                        style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 18,
                      color: sisaSaatIni() > 0 ? AppColors.textSecondary : AppColors.warning,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Sisa stok: ${sisaSaatIni()}',
                      style: TextStyle(
                        color: sisaSaatIni() > 0 ? AppColors.textSecondary : AppColors.warning,
                        fontWeight: sisaSaatIni() > 0 ? FontWeight.w400 : FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  hintText: 'Masukkan jumlah',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => setStateDialog(() => qty = int.tryParse(value) ?? 1),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (selectedBarang == null || qty <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pilih barang dan masukkan jumlah yang valid')),
                );
                return;
              }
              final sisa = sisaSaatIni();
              if (qty > sisa) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Qty melebihi sisa stok')),
                );
                return;
              }
              _addItem(selectedBarang!, qty);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // Dialog edit kuantitas untuk item yang sudah ditambahkan
  void _editItemQty(int index) {
    int qty = _items[index]['QTY'] as int;
    final harga = _items[index]['HARGA'] as double;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Quantity'),
        content: TextFormField(
          decoration: const InputDecoration(labelText: 'Qty'),
          keyboardType: TextInputType.number,
          initialValue: qty.toString(),
          onChanged: (v) => qty = int.tryParse(v) ?? qty,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                final oldSubtotal = _items[index]['SUBTOTAL'] as double;
                _grossTotal -= oldSubtotal;
                final newSubtotal = harga * qty;
                _items[index]['QTY'] = qty;
                _items[index]['SUBTOTAL'] = newSubtotal;
                _grossTotal += newSubtotal;
                _recalculateTotals();
              });
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  bool get _formValid =>
      _selectedCustomer != null && _selectedMetode != null;

  int _cartQtyForKode(String kode) {
    return _items
        .where((it) => (it['KODE_BARANG'] as String) == kode)
        .fold<int>(0, (sum, it) => sum + (it['QTY'] as int));
  }

  bool _isCreditMethodName(String name) {
    final n = name.toLowerCase();
    return n.contains('kredit') || n.contains('piutang');
  }
}

String _formatRupiah(num value) {
  return NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(value);
}

// Warna badge membership berdasarkan level potongan
Color _badgeColorForDiscount(double percent) {
  if (percent >= 15) return const Color(0xFFE53935); // merah
  if (percent >= 10) return const Color(0xFFFFC107); // amber
  if (percent >= 5) return AppColors.success; // hijau
  return AppColors.textSecondary; // default
}
