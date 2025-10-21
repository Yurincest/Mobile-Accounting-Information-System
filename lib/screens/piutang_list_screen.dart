import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:sia_mobile_soosvaldo/utils/rupiah_input_formatter.dart';
import 'package:sia_mobile_soosvaldo/routes.dart';
import 'package:sia_mobile_soosvaldo/models/piutang_model.dart';
import 'package:sia_mobile_soosvaldo/services/piutang_service.dart';
import 'package:sia_mobile_soosvaldo/models/kartu_piutang_model.dart';

class PiutangListScreen extends StatefulWidget {
  const PiutangListScreen({super.key});

  @override
  PiutangListScreenState createState() => PiutangListScreenState();
}

class PiutangListScreenState extends State<PiutangListScreen> with RouteAware {
  final PiutangService _service = PiutangService();
  late Future<List<PiutangModel>> _piutangList;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  DateTimeRange? _dateRange;
  double? _minAmount;
  double? _maxAmount;
  bool?
  _filterJatuhTempo; // null = all, true = jatuh tempo, false = belum jatuh tempo
  int? _minUmurHari; // untuk filter aging minimal hari
  String _sortBy =
      'date_desc'; // opsi: date_desc, date_asc, sisa_desc, sisa_asc

  @override
  void initState() {
    super.initState();
    _piutangList = _service.getPiutang();
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim();
      if (_searchQuery != q) {
        setState(() => _searchQuery = q);
      }
    });
  }

  void _refresh() {
    setState(() {
      _piutangList = _service.getPiutang();
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
    // Dipanggil saat kembali ke layar ini dari layar lain
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Piutang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          PopupMenuButton<String>(
            onSelected: (val) => setState(() {
              _piutangList = _service.getPiutang();
            }),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'refresh', child: Text('Refresh')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Cari (kode piutang / nota / customer)',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: FutureBuilder<List<PiutangModel>>(
                future: _piutangList,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    List<PiutangModel> data = snapshot.data!;
                    if (_searchQuery.isNotEmpty) {
                      final q = _searchQuery.toLowerCase();
                      data = data.where((p) {
                        return p.kodePiutang.toLowerCase().contains(q) ||
                            p.kodeNota.toLowerCase().contains(q) ||
                            (p.namaCustomer ?? '').toLowerCase().contains(q) ||
                            (p.kodeMetode ?? '').toLowerCase().contains(q);
                      }).toList();
                    }
                    if (_dateRange != null) {
                      data = data.where((p) {
                        if (p.tanggal == null) return false;
                        final dt = _tryParseDate(p.tanggal!);
                        if (dt == null) return false;
                        return dt.isAfter(
                              _dateRange!.start.subtract(
                                const Duration(days: 1),
                              ),
                            ) &&
                            dt.isBefore(
                              _dateRange!.end.add(const Duration(days: 1)),
                            );
                      }).toList();
                    }
                    if (_minAmount != null) {
                      data = data.where((p) => p.sisa >= _minAmount!).toList();
                    }
                    if (_maxAmount != null) {
                      data = data.where((p) => p.sisa <= _maxAmount!).toList();
                    }
                    if (_filterJatuhTempo != null) {
                      data = data
                          .where(
                            (p) =>
                                (p.isJatuhTempo ?? false) == _filterJatuhTempo,
                          )
                          .toList();
                    }
                    if (_minUmurHari != null) {
                      data = data
                          .where((p) => (p.umurHari ?? 0) >= _minUmurHari!)
                          .toList();
                    }

                    // Sorting default: terbaru ke terlama
                    data.sort((a, b) {
                      final aD = a.tanggal != null
                          ? (_tryParseDate(a.tanggal!) ??
                                DateTime.fromMillisecondsSinceEpoch(0))
                          : DateTime.fromMillisecondsSinceEpoch(0);
                      final bD = b.tanggal != null
                          ? (_tryParseDate(b.tanggal!) ??
                                DateTime.fromMillisecondsSinceEpoch(0))
                          : DateTime.fromMillisecondsSinceEpoch(0);
                      switch (_sortBy) {
                        case 'date_asc':
                          return aD.compareTo(bD);
                        case 'date_desc':
                          return bD.compareTo(aD);
                        case 'sisa_asc':
                          return a.sisa.compareTo(b.sisa);
                        case 'sisa_desc':
                          return b.sisa.compareTo(a.sisa);
                        default:
                          return bD.compareTo(aD);
                      }
                    });

                    if (data.isEmpty) {
                      return const Center(child: Text('Belum ada data'));
                    }
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final double maxW = constraints.maxWidth < 600
                            ? constraints.maxWidth
                            : (constraints.maxWidth < 1024 ? 820 : 1100);
                        return Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxW),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              itemCount: data.length,
                              itemBuilder: (context, index) {
                                final p = data[index];
                                final isOverdue = p.isJatuhTempo == true;
                                final isPaid = p.sisa <= 0;
                                final showDue = !isPaid;
                                final color = isPaid
                                    ? Colors.green.shade100
                                    : (isOverdue
                                          ? Colors.red.shade100
                                          : Colors.orange.shade100);
                                final badge = isOverdue
                                    ? 'Jatuh Tempo'
                                    : 'Belum Jatuh Tempo';
                                return Card(
                                  color: color,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: ExpansionTile(
                                    title: Text(
                                      'Piutang: ${p.kodePiutang} | Nota: ${p.kodeNota}${p.namaCustomer != null && p.namaCustomer!.isNotEmpty ? ' | Customer: ${p.namaCustomer}' : ''}',
                                    ),
                                    subtitle: Text(
                                      'Tanggal: ${p.tanggal ?? '-'}'
                                      '${showDue ? ' | Due: ${p.dueDate ?? '-'}' : ''}'
                                      '${showDue ? ' | Umur: ${p.umurHari ?? 0} hari' : ''}'
                                      ' | Total: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(p.total)}'
                                      ' | Sisa: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(p.sisa)}'
                                      ' | Status: ${p.sisa > 0 ? 'Belum Lunas' : 'Lunas'}'
                                      '${isPaid && p.tanggalLunas != null ? ' | Lunas: ${_formatDate(p.tanggalLunas!)}' : (showDue ? ' | $badge' : '')}',
                                    ),
                                    trailing: p.sisa > 0
                                        ? Wrap(
                                            spacing: 8,
                                            children: [
                                              TextButton.icon(
                                                onPressed: () => _showAddCicilanDialog(p),
                                                icon: const Icon(Icons.payment),
                                                label: const Text('Bayar'),
                                              ),
                                              TextButton.icon(
                                                onPressed: () => _confirmAndLunasi(p),
                                                icon: const Icon(Icons.done_all),
                                                label: const Text('Lunasi'),
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors.green.shade700,
                                                ),
                                              ),
                                            ],
                                          )
                                        : const Icon(Icons.check_circle, color: Colors.green),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        child: FutureBuilder<List<KartuPiutangRow>>(
                                          future: _service.getKartuPiutangHistory(p.kodePiutang),
                                          builder: (context, hSnap) {
                                            final currency = NumberFormat.currency(
                                              locale: 'id_ID',
                                              symbol: 'Rp ',
                                              decimalDigits: 0,
                                            );
                                            if (hSnap.hasError) {
                                              return Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Text('Gagal memuat histori: ${hSnap.error}'),
                                              );
                                            }
                                            if (!hSnap.hasData) {
                                              return const Center(child: LinearProgressIndicator());
                                            }
                                            final rowsData = hSnap.data!;
                                            if (rowsData.isEmpty) {
                                              return const Center(child: Text('Tidak ada histori untuk nota ini.'));
                                            }
                                            final header = const TableRow(
                                              children: [
                                                Padding(
                                                  padding: EdgeInsets.all(8),
                                                  child: Text(
                                                    'Tanggal',
                                                    maxLines: 1,
                                                    softWrap: false,
                                                    style: TextStyle(fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(8),
                                                  child: Text(
                                                    'Keterangan',
                                                    maxLines: 1,
                                                    softWrap: false,
                                                    style: TextStyle(fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(8),
                                                  child: Align(
                                                    alignment: Alignment.centerRight,
                                                    child: Text(
                                                      'Debit',
                                                      maxLines: 1,
                                                      softWrap: false,
                                                      style: TextStyle(fontWeight: FontWeight.w600),
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(8),
                                                  child: Align(
                                                    alignment: Alignment.centerRight,
                                                    child: Text(
                                                      'Kredit',
                                                      maxLines: 1,
                                                      softWrap: false,
                                                      style: TextStyle(fontWeight: FontWeight.w600),
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(8),
                                                  child: Align(
                                                    alignment: Alignment.centerRight,
                                                    child: Text(
                                                      'Saldo',
                                                      maxLines: 1,
                                                      softWrap: false,
                                                      style: TextStyle(fontWeight: FontWeight.w600),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                            final tableRows = <TableRow>[header];
                                            for (final r in rowsData) {
                                              tableRows.add(
                                                TableRow(
                                                  children: [
                                                    Padding(
                                                      padding: const EdgeInsets.all(8),
                                                      child: Text(r.tanggal ?? '-'),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.all(8),
                                                      child: Text(r.keterangan, overflow: TextOverflow.ellipsis),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.all(8),
                                                      child: Align(
                                                        alignment: Alignment.centerRight,
                                                        child: Text(currency.format(r.debit)),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.all(8),
                                                      child: Align(
                                                        alignment: Alignment.centerRight,
                                                        child: Text(currency.format(r.kredit)),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.all(8),
                                                      child: Align(
                                                        alignment: Alignment.centerRight,
                                                        child: Text(currency.format(r.saldo)),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }
                                            final double headerH = 52.0;
                                            final double rowH = 44.0;
                                            final double maxH = 360.0;
                                            final double tableH = math.min(headerH + rowsData.length * rowH, maxH);
                                            final Widget horiz = SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: IntrinsicWidth(
                                                child: Table(
                                                  columnWidths: const {
                                                    0: FixedColumnWidth(160),
                                                    1: FixedColumnWidth(360),
                                                    2: FixedColumnWidth(140),
                                                    3: FixedColumnWidth(140),
                                                    4: FixedColumnWidth(160),
                                                  },
                                                  children: tableRows,
                                                ),
                                              ),
                                            );
                                            return SizedBox(
                                              height: tableH,
                                              child: SingleChildScrollView(child: horiz),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error.toString()}'),
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showKartuPiutangDialog(PiutangModel p) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text('Kartu Piutang - Nota ${p.kodeNota}'),
        content: SizedBox(
          width: 800,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ringkasan
              Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Tanggal: ${p.tanggal ?? '-'}'),
                  Text('Total: ${currency.format(p.total)}'),
                  Text('Sisa: ${currency.format(p.sisa)}'),
                  _buildStatusBadge(p.sisa > 0),
                ],
              ),
              const SizedBox(height: 8),
              // Selector tampilan: Kartu Piutang vs Cicilan
              const TabBar(
                tabs: [
                  Tab(text: 'Kartu Piutang'),
                  Tab(text: 'Cicilan'),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 420,
                child: TabBarView(
                  children: [
                    // Tab 1: Kartu Piutang per-nota
                    FutureBuilder<List<KartuPiutangRow>>(
                      future: _service.getKartuPiutangHistory(p.kodePiutang),
                      builder: (context, hSnap) {
                        if (hSnap.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('Gagal memuat histori: ${hSnap.error}'),
                          );
                        }
                        if (!hSnap.hasData) {
                          return const Center(child: LinearProgressIndicator());
                        }
                        final rowsData = hSnap.data!;
                        if (rowsData.isEmpty) {
                          return const Center(
                            child: Text('Tidak ada histori untuk nota ini.'),
                          );
                        }
                        final header = const TableRow(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                'Tanggal',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                'Keterangan',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'Debit',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'Kredit',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'Saldo',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        );
                        final tableRows = <TableRow>[header];
                        for (final r in rowsData) {
                          tableRows.add(
                            TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(r.tanggal ?? '-'),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(r.keterangan),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(currency.format(r.debit)),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(currency.format(r.kredit)),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(currency.format(r.saldo)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return Table(
                          columnWidths: const {
                            0: FlexColumnWidth(2),
                            1: FlexColumnWidth(4),
                            2: FlexColumnWidth(2),
                            3: FlexColumnWidth(2),
                            4: FlexColumnWidth(2),
                          },
                          children: tableRows,
                        );
                      },
                    ),
                    // Tab 2: Daftar cicilan per-nota
                    FutureBuilder<List<CicilanModel>>(
                      future: _service.getCicilan(p.kodePiutang),
                      builder: (context, cSnap) {
                        if (cSnap.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('Gagal memuat cicilan: ${cSnap.error}'),
                          );
                        }
                        if (!cSnap.hasData) {
                          return const Center(child: LinearProgressIndicator());
                        }
                        final items = cSnap.data!;
                        if (items.isEmpty) {
                          return const Center(
                            child: Text('Belum ada cicilan untuk nota ini.'),
                          );
                        }
                        return ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final c = items[i];
                            return ListTile(
                              leading: const Icon(Icons.payments),
                              title: Text('${c.tanggal}'),
                              subtitle: const Text('Cicilan'),
                              trailing: Text(currency.format(c.jumlah)),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool aktif) {
    final MaterialColor base = aktif ? Colors.red : Colors.green;
    final String label = aktif ? 'Aktif' : 'Lunas';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: base.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: base.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: base.shade700, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _showFilterDialog() {
    DateTimeRange? tempRange = _dateRange;
    double? tempMin = _minAmount;
    double? tempMax = _maxAmount;
    bool? tempJatuhTempo = _filterJatuhTempo;
    int? tempMinUmur = _minUmurHari;
    String tempSortBy = _sortBy;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: const Text('Filter Piutang'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(now.year - 5),
                  lastDate: DateTime(now.year + 1),
                  initialDateRange: tempRange,
                );
                if (picked != null) tempRange = picked;
              },
              child: Text(
                tempRange == null
                    ? 'Pilih Rentang Tanggal Nota'
                    : '${DateFormat('dd/MM/yyyy').format(tempRange!.start)} - ${DateFormat('dd/MM/yyyy').format(tempRange!.end)}',
              ),
            ),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Min Sisa',
                hintText: 'Masukkan minimal sisa',
                prefixText: 'Rp ',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandsSeparatorInputFormatter(),
              ],
              initialValue: tempMin != null
                  ? NumberFormat('#,##0').format(tempMin)
                  : null,
              onChanged: (v) {
                final raw = v.replaceAll('.', '');
                tempMin = double.tryParse(raw);
              },
            ),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Max Sisa',
                hintText: 'Masukkan maksimal sisa',
                prefixText: 'Rp ',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandsSeparatorInputFormatter(),
              ],
              initialValue: tempMax != null
                  ? NumberFormat('#,##0').format(tempMax)
                  : null,
              onChanged: (v) {
                final raw = v.replaceAll('.', '');
                tempMax = double.tryParse(raw);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<bool?>(
              decoration: const InputDecoration(
                labelText: 'Status Jatuh Tempo',
              ),
              initialValue: tempJatuhTempo,
              items: const <DropdownMenuItem<bool?>>[
                DropdownMenuItem<bool?>(child: Text('Semua'), value: null),
                DropdownMenuItem<bool?>(
                  child: Text('Jatuh Tempo'),
                  value: true,
                ),
                DropdownMenuItem<bool?>(
                  child: Text('Belum Jatuh Tempo'),
                  value: false,
                ),
              ],
              onChanged: (v) => tempJatuhTempo = v,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Min Umur Hari'),
              keyboardType: TextInputType.number,
              initialValue: tempMinUmur?.toString(),
              onChanged: (v) => tempMinUmur = int.tryParse(v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Urutkan'),
              value: tempSortBy,
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
                  value: 'sisa_desc',
                  child: Text('Sisa tertinggi'),
                ),
                DropdownMenuItem(
                  value: 'sisa_asc',
                  child: Text('Sisa terendah'),
                ),
              ],
              onChanged: (v) {
                if (v != null) tempSortBy = v;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _dateRange = tempRange;
                _minAmount = tempMin;
                _maxAmount = tempMax;
                _filterJatuhTempo = tempJatuhTempo;
                _minUmurHari = tempMinUmur;
                _sortBy = tempSortBy;
              });
              Navigator.pop(context);
            },
            child: const Text('Terapkan'),
          ),
        ],
      ),
    );
  }

  // Hapus date picker dari dialog cicilan dan gunakan NOW di backend; cukup input jumlah
  void _showAddCicilanDialog(PiutangModel piutang) {
    double jumlah = 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text('Tambah Cicilan untuk ${piutang.kodePiutang}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Jumlah',
                hintText: 'Masukkan jumlah cicilan',
                prefixText: 'Rp ',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandsSeparatorInputFormatter(),
              ],
              onChanged: (value) {
                final raw = value.replaceAll('.', '');
                jumlah = double.tryParse(raw) ?? 0;
              },
              validator: (value) => (jumlah <= 0 || jumlah > piutang.sisa)
                  ? 'Jumlah invalid'
                  : null,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (jumlah > 0 && jumlah <= piutang.sisa) {
                final cicilan = CicilanModel(
                  kodeCicilan: '',
                  kodePiutang: piutang.kodePiutang,
                  tanggal: '',
                  jumlah: jumlah,
                );
                try {
                  await _service.addCicilan(cicilan);
                  if (!context.mounted) return;
                  setState(() {
                    _piutangList = _service.getPiutang();
                  });
                  Navigator.pop(context);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Aksi cepat untuk melunasi seluruh sisa dengan konfirmasi
  void _confirmAndLunasi(PiutangModel piutang) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: const Text('Konfirmasi Pelunasan'),
        content: Text(
          'Lunasi piutang ${piutang.kodePiutang} sebesar sisa '
          '${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(piutang.sisa)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Lunasi'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final cicilan = CicilanModel(
        kodeCicilan: '',
        kodePiutang: piutang.kodePiutang,
        tanggal: '',
        jumlah: piutang.sisa,
      );
      await _service.addCicilan(cicilan);
      if (!context.mounted) return;
      setState(() {
        _piutangList = _service.getPiutang();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Piutang dilunasi')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  DateTime? _tryParseDate(String s) {
    try {
      // coba beberapa format umum dari backend PHP
      if (s.contains('-')) {
        // kemungkinan 'YYYY-MM-DD' atau 'YYYY-MM-DD HH:MM:SS'
        return DateTime.tryParse(s);
      }
      // fallback: dd/MM/yyyy
      return DateFormat('dd/MM/yyyy').parse(s);
    } catch (_) {
      return null;
    }
  }

  String _formatDate(String s) {
    final dt = _tryParseDate(s);
    if (dt == null) return s;
    return DateFormat('dd/MM/yyyy').format(dt);
  }
}
