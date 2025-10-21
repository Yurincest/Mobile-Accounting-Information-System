import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sia_mobile_soosvaldo/models/nota_jual_model.dart';
import 'package:sia_mobile_soosvaldo/services/pos_service.dart';
import 'package:sia_mobile_soosvaldo/routes.dart';

class NotaJualListScreen extends StatefulWidget {
  const NotaJualListScreen({super.key});

  @override
  State<NotaJualListScreen> createState() => _NotaJualListScreenState();
}

class _NotaJualListScreenState extends State<NotaJualListScreen>
    with RouteAware {
  final PosService _service = PosService();
  late Future<List<NotaJualModel>> _notaListFuture;
  // Tambahan: pencarian dan sorting
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _sortBy =
      'date_desc'; // opsi: date_desc, date_asc, total_desc, total_asc

  DateTimeRange? _dateRange;
  bool _onlyBerhutang = false; // DP < TOTAL

  @override
  void initState() {
    super.initState();
    _notaListFuture = _service.getNotaJual();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange:
          _dateRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: DateTime(now.year, now.month + 1, 0),
          ),
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  void _showFilterDialog() {
    DateTimeRange? tempRange = _dateRange;
    bool tempOnlyBerhutang = _onlyBerhutang;
    String tempSortBy = _sortBy;
    final now = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: const Text('Filter Nota Jual'),
        content: StatefulBuilder(
          builder: (context, setInnerState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Rentang tanggal
                TextButton(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(now.year - 3, 1, 1),
                      lastDate: DateTime(now.year + 1, 12, 31),
                      initialDateRange: tempRange ?? _dateRange ?? DateTimeRange(
                        start: DateTime(now.year, now.month, 1),
                        end: DateTime(now.year, now.month + 1, 0),
                      ),
                    );
                    if (picked != null) setInnerState(() => tempRange = picked);
                  },
                  child: Text(
                    tempRange == null
                        ? 'Pilih Rentang Tanggal'
                        : '${DateFormat('dd/MM/yyyy').format(tempRange!.start)} - ${DateFormat('dd/MM/yyyy').format(tempRange!.end)}',
                  ),
                ),
                const SizedBox(height: 8),
                // Hanya yang masih berhutang
                Row(
                  children: [
                    const Text('Masih berhutang'),
                    const SizedBox(width: 12),
                    Switch(
                      value: tempOnlyBerhutang,
                      onChanged: (v) => setInnerState(() => tempOnlyBerhutang = v),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Sorting
                DropdownButtonHideUnderline(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: tempSortBy,
                      items: const [
                        DropdownMenuItem(value: 'date_desc', child: Text('Tanggal terbaru')),
                        DropdownMenuItem(value: 'date_asc', child: Text('Tanggal terlama')),
                        DropdownMenuItem(value: 'total_desc', child: Text('Total tertinggi')),
                        DropdownMenuItem(value: 'total_asc', child: Text('Total terendah')),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setInnerState(() => tempSortBy = v);
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _dateRange = tempRange;
                _onlyBerhutang = tempOnlyBerhutang;
                _sortBy = tempSortBy;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Terapkan'),
          ),
        ],
      ),
    );
  }

  void _refresh() {
    setState(() {
      _notaListFuture = _service.getNotaJual();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // Dipanggil saat kembali ke layar ini dari layar lain (mis. POS)
    _refresh();
  }

  DateTime? _parseDate(String s) {
    try {
      // Expect yyyy-MM-dd or ISO-like
      return DateTime.tryParse(s);
    } catch (_) {
      return null;
    }
  }

  String _formatRupiah(num n) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(n);
  }

  // Helper untuk label sort (opsional)
  String _sortLabel(String v) {
    switch (v) {
      case 'date_desc':
        return 'Tanggal terbaru';
      case 'date_asc':
        return 'Tanggal terlama';
      case 'total_desc':
        return 'Total tertinggi';
      case 'total_asc':
        return 'Total terendah';
      default:
        return 'Tanggal terbaru';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Nota Jual'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          PopupMenuButton<String>(
            onSelected: (val) {
              switch (val) {
                case 'reset_filters':
                  setState(() {
                    _dateRange = null;
                    _onlyBerhutang = false;
                    _searchQuery = '';
                    _searchCtrl.clear();
                    _sortBy = 'date_desc';
                  });
                  break;
                case 'refresh':
                  _refresh();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'refresh', child: Text('Refresh')),
              PopupMenuItem(
                value: 'reset_filters',
                child: Text('Reset Filter'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _dateRange == null
                          ? 'Semua tanggal'
                          : '${DateFormat('dd/MM/yyyy').format(_dateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_dateRange!.end)}',
                    ),
                  ),
                  Row(
                    children: [
                      const Text('Masih berhutang'),
                      Switch(
                        value: _onlyBerhutang,
                        onChanged: (v) => setState(() => _onlyBerhutang = v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Tambahan: bar pencarian dan kontrol sorting
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Cari (kode nota / nama customer / metode)',
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
                  const SizedBox(width: 8),
                  DropdownButtonHideUnderline(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: _sortBy,
                        items: const [
                          DropdownMenuItem(
                            value: 'date_desc',
                            child: Text('Tanggal terbaru'),
                          ),
                          DropdownMenuItem(
                            value: 'date_asc',
                            child: Text('Tanggal terlama'),
                          ),
                          DropdownMenuItem(
                            value: 'total_desc',
                            child: Text('Total tertinggi'),
                          ),
                          DropdownMenuItem(
                            value: 'total_asc',
                            child: Text('Total terendah'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _sortBy = v);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<NotaJualModel>>(
                future: _notaListFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    var data = snapshot.data!;
                    // Filter by date
                    if (_dateRange != null) {
                      data = data.where((n) {
                        final d = _parseDate(n.tanggal);
                        if (d == null) return false;
                        return d.isAfter(
                              _dateRange!.start.subtract(
                                const Duration(days: 1),
                              ),
                            ) &&
                            d.isBefore(
                              _dateRange!.end.add(const Duration(days: 1)),
                            );
                      }).toList();
                    }
                    // Filter only berhutang
                    if (_onlyBerhutang) {
                      data = data.where((n) => n.dp < n.total).toList();
                    }
                    // Filter by search query (kode nota atau NIK customer)
                    if (_searchQuery.isNotEmpty) {
                      final q = _searchQuery.toLowerCase().trim();
                      data = data
                          .where(
                            (n) =>
                                n.kodeNota.toLowerCase().contains(q) ||
                                n.nikCustomer.toLowerCase().contains(q) ||
                                n.kodeMetode.toLowerCase().contains(q),
                          )
                          .toList();
                    }
                    // Sorting
                    data.sort((a, b) {
                      final aD =
                          _parseDate(a.tanggal) ??
                          DateTime.fromMillisecondsSinceEpoch(0);
                      final bD =
                          _parseDate(b.tanggal) ??
                          DateTime.fromMillisecondsSinceEpoch(0);
                      switch (_sortBy) {
                        case 'date_asc':
                          return aD.compareTo(bD);
                        case 'date_desc':
                          return bD.compareTo(aD);
                        case 'total_asc':
                          return a.total.compareTo(b.total);
                        case 'total_desc':
                          return b.total.compareTo(a.total);
                        default:
                          return bD.compareTo(aD);
                      }
                    });

                    if (data.isEmpty) {
                      return const Center(child: Text('Belum ada data'));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final n = data[index];
                        final berhutang = n.dp < n.total;
                        final sisa = (n.total - n.dp).clamp(0, double.infinity);
                        final chips = <Widget>[];
                        chips.add(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (berhutang
                                  ? Colors.orange.shade100
                                  : Colors.green.shade100),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: berhutang ? Colors.orange : Colors.green,
                              ),
                            ),
                            child: Text(berhutang ? 'Belum Lunas' : 'Lunas'),
                          ),
                        );

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: ExpansionTile(
                            childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            title: Text('Nota ${n.kodeNota}'),
                            subtitle: Text(
                              'Tanggal: ${n.tanggal} | Customer: ${n.nikCustomer} | Metode: ${n.kodeMetode}\nTotal: ${_formatRupiah(n.total)} | DP: ${_formatRupiah(n.dp)} | Sisa: ${_formatRupiah(sisa)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: chips,
                            ),
                            children: [
                            FutureBuilder<List<DetailNotaModel>>(
                              future: _service.getDetailNota(n.kodeNota),
                              builder: (context, detailSnap) {
                                if (detailSnap.hasData) {
                                  final details = detailSnap.data!;
                                  return ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: details.length,
                                    itemBuilder: (context, dIndex) {
                                      final d = details[dIndex];
                                      return Card(
                                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          title: Text('Barang: ${d.namaBarang}'),
                                          subtitle: Text(
                                            'Qty: ${d.qty} | Harga: ${_formatRupiah(d.harga)} | Subtotal: ${_formatRupiah(d.subtotal)}',
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                } else if (detailSnap.hasError) {
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      'Error memuat detail: ${detailSnap.error}',
                                    ),
                                  );
                                }
                                return const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                        );
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
