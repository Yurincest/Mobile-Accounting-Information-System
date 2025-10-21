import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:sia_mobile_soosvaldo/models/accounting_model.dart';
import 'package:sia_mobile_soosvaldo/services/accounting_service.dart';
import 'package:sia_mobile_soosvaldo/screens/kartu_piutang_screen.dart';

class AccountingScreen extends StatefulWidget {
  const AccountingScreen({super.key});

  @override
  AccountingScreenState createState() => AccountingScreenState();
}

class AccountingScreenState extends State<AccountingScreen>
    with SingleTickerProviderStateMixin {
  final AccountingService _service = AccountingService();
  late TabController _tabController;

  DateTime? _startDate;
  DateTime? _endDate;
  // Pilihan akun multi-select untuk Buku Besar
  Set<String> _selectedAkunSet = {};
  String? _selectedAkun; // legacy, akan dihapus bertahap
  bool _isMonthFilter = false;
  bool _showAllBukuBesar = true;
  String _bukuBesarFilterMode = 'all';

  Widget _labelChip(String label, MaterialColor baseColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: baseColor.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: baseColor.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      if (!mounted) return;
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _isMonthFilter = false;
      });
    }
  }

  Future<void> _selectMonth() async {
    int selectedYear = _startDate?.year ?? DateTime.now().year;
    int selectedMonth = _startDate?.month ?? DateTime.now().month;

    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) {
        int tempYear = selectedYear;
        int tempMonth = selectedMonth;
        return StatefulBuilder(
          builder: (context, setInnerState) {
            return AlertDialog(
              titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: const Text('Pilih Bulan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tahun'),
                  DropdownButton<int>(
                    value: tempYear,
                    items: List.generate(102, (i) {
                      final year = 2000 + i;
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }),
                    onChanged: (v) {
                      if (v != null) setInnerState(() => tempYear = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text('Bulan'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(12, (i) {
                      final m = i + 1;
                      return ChoiceChip(
                        label: Text(
                          DateFormat('MMM').format(DateTime(2000, m, 1)),
                        ),
                        selected: tempMonth == m,
                        onSelected: (_) => setInnerState(() => tempMonth = m),
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pop({'year': tempYear, 'month': tempMonth}),
                  child: const Text('Pilih'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      final startOfMonth = DateTime(result['year']!, result['month']!, 1);
      final endOfMonth = DateTime(result['year']!, result['month']! + 1, 0);
      if (!mounted) return;
      setState(() {
        _startDate = startOfMonth;
        _endDate = endOfMonth;
        _isMonthFilter = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Akuntansi'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Jurnal Umum'),
            Tab(text: 'Buku Besar'),
            Tab(text: 'Neraca Saldo'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // ElevatedButton(
                //   onPressed: _selectDateRange,
                //   child: const Text('Pilih Rentang Tanggal'),
                // ),
                ElevatedButton(
                  onPressed: _selectMonth,
                  child: const Text('Pilih Bulan'),
                ),
                if (_startDate != null && _endDate != null)
                  Text(
                    _isMonthFilter
                        ? DateFormat('MM/yyyy').format(_startDate!)
                        : '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                  ),
              ],
            ),
          ),
          if (_tabController.index == 1) // Untuk Buku Besar
            FutureBuilder<List<NeracaSaldoModel>>(
              future: _service.getNeracaSaldo(
                startDate: _startDate != null
                    ? DateFormat('yyyy-MM-dd').format(_startDate!)
                    : null,
                endDate: _endDate != null
                    ? DateFormat('yyyy-MM-dd').format(_endDate!)
                    : null,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final items = snapshot.data!
                      .where(
                        (e) =>
                            e.totalDebit != 0 ||
                            e.totalKredit != 0 ||
                            e.saldo != 0,
                      )
                      .toList();
                  final codes = items.map((e) => e.kodeAkun).toSet();
                  if (_selectedAkun != null && !codes.contains(_selectedAkun)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _selectedAkun = null);
                    });
                  }
                  if (items.isEmpty) {
                    return const Text(
                      'Tidak ada akun dengan saldo atau transaksi.',
                    );
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final double maxW = constraints.maxWidth < 600
                          ? constraints.maxWidth
                          : (constraints.maxWidth < 1024 ? 820 : 1100);
                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxW),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          icon: const Icon(Icons.filter_list),
                          label: const Text('Filter Akun'),
                          onPressed: () async {
                            final selectedLocal = Set<String>.from(
                              _selectedAkunSet,
                            );
                            bool showAllLocal = _showAllBukuBesar;
                            await showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (ctx) {
                                return StatefulBuilder(
                                  builder: (ctx, setInner) {
                                    return SafeArea(
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Filter Buku Besar',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            SwitchListTile(
                                              title: const Text(
                                                'Lihat Semua Akun',
                                              ),
                                              value: showAllLocal,
                                              onChanged: (v) {
                                                setInner(() {
                                                  showAllLocal = v;
                                                });
                                              },
                                            ),
                                            if (!showAllLocal)
                                              Flexible(
                                                child: ListView(
                                                  shrinkWrap: true,
                                                  children: items.map((n) {
                                                    final checked =
                                                        selectedLocal.contains(
                                                          n.kodeAkun,
                                                        );
                                                    return CheckboxListTile(
                                                      value: checked,
                                                      title: Text(
                                                        '${n.kodeAkun} - ${n.namaAkun}',
                                                      ),
                                                      onChanged: (val) {
                                                        setInner(() {
                                                          if (val == true) {
                                                            selectedLocal.add(
                                                              n.kodeAkun,
                                                            );
                                                          } else {
                                                            selectedLocal
                                                                .remove(
                                                                  n.kodeAkun,
                                                                );
                                                          }
                                                        });
                                                      },
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                TextButton(
                                                  onPressed: () {
                                                    setInner(() {
                                                      selectedLocal.clear();
                                                      showAllLocal = true;
                                                    });
                                                  },
                                                  child: const Text(
                                                    'Bersihkan',
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      _showAllBukuBesar =
                                                          showAllLocal;
                                                      _selectedAkunSet =
                                                          selectedLocal;
                                                    });
                                                    Navigator.pop(ctx);
                                                  },
                                                  child: const Text('Terapkan'),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                              if (_showAllBukuBesar || items.any((n) => _selectedAkunSet.contains(n.kodeAkun) && n.namaAkun.toUpperCase().contains('PIUTANG')))
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.credit_card),
                                    label: const Text('Kartu Piutang'),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const KartuPiutangScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Text('Gagal memuat akun: ${snapshot.error}');
                }
                return const CircularProgressIndicator();
              },
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double maxW = constraints.maxWidth < 600
                    ? constraints.maxWidth
                    : (constraints.maxWidth < 1024 ? 820 : 1100);
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxW),
                    child: TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildJurnalUmum(),
                        _buildBukuBesar(),
                        _buildNeracaSaldo(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJurnalUmum() {
    return FutureBuilder<List<JurnalUmumModel>>(
      future: _service.getJurnalUmum(
        startDate: _startDate != null
            ? DateFormat('yyyy-MM-dd').format(_startDate!)
            : null,
        endDate: _endDate != null
            ? DateFormat('yyyy-MM-dd').format(_endDate!)
            : null,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final jurnals = snapshot.data!;
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: FutureBuilder<MonthlySummary>(
                  future: _service.getMonthlySummary(
                    startDate: _startDate != null
                        ? DateFormat('yyyy-MM-dd').format(_startDate!)
                        : null,
                    endDate: _endDate != null
                        ? DateFormat('yyyy-MM-dd').format(_endDate!)
                        : null,
                  ),
                  builder: (context, sumSnapshot) {
                    if (sumSnapshot.hasError) {
                      return Text(
                        'Ringkasan gagal dimuat: ${sumSnapshot.error}',
                      );
                    }
                    if (!sumSnapshot.hasData) {
                      return const LinearProgressIndicator();
                    }
                    final summary = sumSnapshot.data!;
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Total Debit: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(summary.totalDebit).replaceAll('Rp ', 'Rp\u00A0')}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Total Kredit: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(summary.totalKredit).replaceAll('Rp ', 'Rp\u00A0')}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              ...jurnals.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final jurnal = entry.value;
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black.withOpacity(0.15)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      radius: MediaQuery.of(context).size.width < 360 ? 12 : 14,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.15),
                      child: Text(
                        '$idx',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    title: Text(
                      '#$idx ${jurnal.kodeJurnal}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${jurnal.tanggal} - ${jurnal.keterangan}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (MediaQuery.of(context).size.width < 480)
                          FutureBuilder<List<JurnalDetailModel>>(
                            future:
                                _service.getJurnalDetail(jurnal.kodeJurnal),
                            builder: (context, tSnapshot) {
                              if (!tSnapshot.hasData) {
                                return const SizedBox.shrink();
                              }
                              final det = tSnapshot.data!;
                              final hasKas = det.any(
                                (d) =>
                                    d.namaAkun
                                        .toUpperCase()
                                        .contains('KAS') ||
                                    d.kodeAkun
                                        .toUpperCase()
                                        .contains('KAS'),
                              );
                              final hasPiutang = det.any(
                                (d) =>
                                    d.namaAkun
                                        .toUpperCase()
                                        .contains('PIUTANG') ||
                                    d.kodeAkun
                                        .toUpperCase()
                                        .contains('PIUTANG'),
                              );
                              final hasPendapatan = det.any(
                                (d) =>
                                    d.namaAkun
                                        .toUpperCase()
                                        .contains('PENDAPATAN') ||
                                    d.kodeAkun
                                        .toUpperCase()
                                        .contains('PENDAPATAN'),
                              );
                              final hasPendapatanMembership = det.any(
                                (d) =>
                                    d.kodeAkun.toString() == '4002' ||
                                    d.namaAkun
                                        .toUpperCase()
                                        .contains('PENDAPATAN MEMBERSHIP'),
                              );
                              final kasDebit = det.any(
                                (d) =>
                                    (d.namaAkun
                                                .toUpperCase()
                                                .contains('KAS') ||
                                            d.kodeAkun
                                                .toUpperCase()
                                                .contains('KAS')) &&
                                    d.debit > 0,
                              );
                              final piutangDebit = det.any(
                                (d) =>
                                    (d.namaAkun
                                                .toUpperCase()
                                                .contains('PIUTANG') ||
                                            d.kodeAkun
                                                .toUpperCase()
                                                .contains('PIUTANG')) &&
                                    d.debit > 0,
                              );
                              final pendapatanKredit = det.any(
                                (d) =>
                                    (d.namaAkun
                                                .toUpperCase()
                                                .contains('PENDAPATAN') ||
                                            d.kodeAkun
                                                .toUpperCase()
                                                .contains('PENDAPATAN')) &&
                                    d.kredit > 0,
                              );
                              final isDP =
                                  kasDebit && piutangDebit && pendapatanKredit;
                              final chips = <Widget>[];
                              if (isDP) {
                                chips.add(_labelChip('DP', Colors.purple));
                              }
                              if (hasKas) {
                                chips.add(_labelChip('Kas', Colors.green));
                              }
                              if (hasPiutang) {
                                chips
                                    .add(_labelChip('Piutang', Colors.orange));
                              }
                              if (hasPendapatanMembership) {
                                chips.add(_labelChip(
                                    'Pendapatan Membership', Colors.blue));
                              } else if (hasPendapatan) {
                                chips.add(_labelChip('Pendapatan', Colors.blue));
                              }
                              if (chips.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding:
                                    const EdgeInsets.only(top: 4.0, right: 8.0),
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: chips,
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                    trailing: FutureBuilder<List<JurnalDetailModel>>(
                      future: _service.getJurnalDetail(jurnal.kodeJurnal),
                      builder: (context, tSnapshot) {
                        final w = MediaQuery.of(context).size.width;
                        if (!tSnapshot.hasData || w < 480) {
                          return const SizedBox.shrink();
                        }
                        final det = tSnapshot.data!;
                        final hasKas = det.any(
                          (d) =>
                              d.namaAkun.toUpperCase().contains('KAS') ||
                              d.kodeAkun.toUpperCase().contains('KAS'),
                        );
                        final hasPiutang = det.any(
                          (d) =>
                              d.namaAkun.toUpperCase().contains('PIUTANG') ||
                              d.kodeAkun.toUpperCase().contains('PIUTANG'),
                        );
                        final hasPendapatan = det.any(
                          (d) =>
                              d.namaAkun.toUpperCase().contains('PENDAPATAN') ||
                              d.kodeAkun.toUpperCase().contains('PENDAPATAN'),
                        );
                        // Tampilkan label khusus untuk Pendapatan Membership bila akun 4002 atau nama mengandung kata tersebut
                        final hasPendapatanMembership = det.any(
                          (d) =>
                              d.kodeAkun.toString() == '4002' ||
                              d.namaAkun.toUpperCase().contains(
                                'PENDAPATAN MEMBERSHIP',
                              ),
                        );
                        final kasDebit = det.any(
                          (d) =>
                              (d.namaAkun.toUpperCase().contains('KAS') ||
                                  d.kodeAkun.toUpperCase().contains('KAS')) &&
                              d.debit > 0,
                        );
                        final piutangDebit = det.any(
                          (d) =>
                              (d.namaAkun.toUpperCase().contains('PIUTANG') ||
                                  d.kodeAkun.toUpperCase().contains(
                                    'PIUTANG',
                                  )) &&
                              d.debit > 0,
                        );
                        final pendapatanKredit = det.any(
                          (d) =>
                              (d.namaAkun.toUpperCase().contains(
                                    'PENDAPATAN',
                                  ) ||
                                  d.kodeAkun.toUpperCase().contains(
                                    'PENDAPATAN',
                                  )) &&
                              d.kredit > 0,
                        );
                        final isDP =
                            kasDebit && piutangDebit && pendapatanKredit;
                        final chips = <Widget>[];
                        if (isDP) {
                          chips.add(_labelChip('DP', Colors.purple));
                        }
                        if (hasKas) {
                          chips.add(_labelChip('Kas', Colors.green));
                        }
                        if (hasPiutang) {
                          chips.add(_labelChip('Piutang', Colors.orange));
                        }
                        if (hasPendapatanMembership) {
                          chips.add(
                            _labelChip('Pendapatan Membership', Colors.blue),
                          );
                        } else if (hasPendapatan) {
                          chips.add(_labelChip('Pendapatan', Colors.blue));
                        }
                        if (chips.isEmpty) return const SizedBox.shrink();
                        return Wrap(spacing: 6, runSpacing: 4, children: chips);
                      },
                    ),
                    children: [
                      // Hapus chips di dalam konten untuk menghindari duplikasi saat expand
                      // (chips sudah ditampilkan di subtitle/trailing sesuai lebar layar)
                      FutureBuilder<List<JurnalDetailModel>>(
                        future: _service.getJurnalDetail(jurnal.kodeJurnal),
                        builder: (context, detailSnapshot) {
                          if (detailSnapshot.hasError) {
                            return Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                'Gagal memuat detail: ${detailSnapshot.error}',
                              ),
                            );
                          } else if (detailSnapshot.hasData) {
                            final details = detailSnapshot.data!;
                            if (details.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Text(
                                  'Tidak ada detail untuk jurnal ini.',
                                ),
                              );
                            }
                            final currency = NumberFormat.currency(
                              locale: 'id_ID',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            );
                            final debits = details
                                .where((d) => d.debit > 0)
                                .where(
                                  (d) => !(d.kodeAkun.toUpperCase().startsWith(
                                    'BARANG',
                                  )),
                                )
                                .toList();
                            final kredits = details
                                .where((d) => d.kredit > 0)
                                .where(
                                  (d) => !(d.kodeAkun.toUpperCase().startsWith(
                                    'BARANG',
                                  )),
                                )
                                .toList();

                            // Pastikan urutan debit: Kas dulu lalu Piutang
                            int weight(JurnalDetailModel d) {
                              final n = d.namaAkun.toUpperCase();
                              final k = d.kodeAkun.toUpperCase();
                              final isKas =
                                  n.contains('KAS') ||
                                  k == '1001' ||
                                  k.startsWith('100');
                              final isPiutang =
                                  n.contains('PIUTANG') ||
                                  k == '1101' ||
                                  k.startsWith('110');
                              if (isKas) return 0;
                              if (isPiutang) return 1;
                              return 2;
                            }

                            debits.sort(
                              (a, b) => weight(a).compareTo(weight(b)),
                            );

                            final isDP =
                                debits.any((d) {
                                  final n = d.namaAkun.toUpperCase();
                                  final k = d.kodeAkun.toUpperCase();
                                  return n.contains('KAS') ||
                                      k == '1001' ||
                                      k.startsWith('100');
                                }) &&
                                debits.any((d) {
                                  final n = d.namaAkun.toUpperCase();
                                  final k = d.kodeAkun.toUpperCase();
                                  return n.contains('PIUTANG') ||
                                      k == '1101' ||
                                      k.startsWith('110');
                                }) &&
                                kredits.any((d) {
                                  final n = d.namaAkun.toUpperCase();
                                  final k = d.kodeAkun.toUpperCase();
                                  return n.contains('PENDAPATAN') ||
                                      k.contains('PENDAPATAN');
                                });

                            List<TableRow> _rows(
                              List<JurnalDetailModel> list,
                              bool isDebit,
                            ) {
                              return list
                                  .map(
                                    (d) => TableRow(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6.0,
                                            horizontal: 0.0,
                                          ),
                                          child: Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  '${d.kodeAkun}${d.namaAkun.isNotEmpty ? ' - ${d.namaAkun}' : ''}',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 2),
                                              Expanded(
                                                child: Container(
                                                  height: 1,
                                                  color: Colors.black
                                                      .withOpacity(0.15),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6.0,
                                            horizontal: 0.0,
                                          ),
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              currency.format(
                                                isDebit ? d.debit : d.kredit,
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList();
                            }

                            final allItems = details
                                .expand((d) => d.items)
                                .toList();

                            // Gabungkan Debit dan Kredit dalam satu tabel (stacking)
                            final List<TableRow> stackedRows = [
                              const TableRow(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 6.0,
                                      horizontal: 8.0,
                                    ),
                                    child: Text(
                                      'Kode - Nama Akun',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 6.0,
                                      horizontal: 8.0,
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        'Debit',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 6.0,
                                      horizontal: 8.0,
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        'Kredit',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Baris-baris Debit (jumlah di kolom Debit, kolom Kredit kosong)
                              ...debits.map(
                                (d) => TableRow(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6.0,
                                        horizontal: 0.0,
                                      ),
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              '${d.kodeAkun}${d.namaAkun.isNotEmpty ? ' - ${d.namaAkun}' : ''}',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          LayoutBuilder(
                                            builder: (context, constraints) {
                                              final double maxWidth = constraints.maxWidth;
                                              final double lineWidth = math.min(maxWidth * 0.25, 80);
                                              return SizedBox(
                                                width: lineWidth,
                                                child: Container(
                                                  height: 1,
                                                  color: Colors.black.withOpacity(0.12),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6.0,
                                        horizontal: 0.0,
                                      ),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        currency
                                            .format(d.debit)
                                            .replaceAll('Rp ', 'Rp\u00A0'),
                                        textAlign: TextAlign.right,
                                        maxLines: 1,
                                        softWrap: false,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    ),
                                    const SizedBox.shrink(),
                                  ],
                                ),
                              ),
                              // Baris-baris Kredit (jumlah di kolom Kredit, kolom Debit kosong)
                              ...kredits.map(
                                (d) => TableRow(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6.0,
                                        horizontal: 0.0,
                                      ),
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              '${d.kodeAkun}${d.namaAkun.isNotEmpty ? ' - ${d.namaAkun}' : ''}',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          LayoutBuilder(
                                            builder: (context, constraints) {
                                              final double maxWidth = constraints.maxWidth;
                                              final double lineWidth = math.min(maxWidth * 0.25, 80);
                                              return SizedBox(
                                                width: lineWidth,
                                                child: Container(
                                                  height: 1,
                                                  color: Colors.black.withOpacity(0.12),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox.shrink(),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6.0,
                                        horizontal: 0.0,
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          currency
                                              .format(d.kredit)
                                              .replaceAll('Rp ', 'Rp\u00A0'),
                                          textAlign: TextAlign.right,
                                          maxLines: 1,
                                          softWrap: false,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Indikator DP sebagai baris penjelas di bawah
                              if (isDP)
                                const TableRow(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 6.0,
                                        horizontal: 8.0,
                                      ),
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: Color(0xFFE0E0E0),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 4.0,
                                            horizontal: 6.0,
                                          ),
                                          child: Text(
                                            'Pendapatan dengan DP',
                                            style: TextStyle(
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox.shrink(),
                                    SizedBox.shrink(),
                                  ],
                                ),
                            ];

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: IntrinsicWidth(
                                    child: Table(
                                      columnWidths: const {
                                        0: FixedColumnWidth(360),
                                        1: FixedColumnWidth(140),
                                        2: FixedColumnWidth(140),
                                      },
                                      children: stackedRows,
                                    ),
                                  ),
                                ),
                                if (allItems.isNotEmpty) ...[
                                  const Padding(
                                    padding: EdgeInsets.only(
                                      left: 8.0,
                                      bottom: 4.0,
                                      top: 12.0,
                                    ),
                                    child: Text(
                                      'Rincian Barang Terjual',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Table(
                                    columnWidths: const {
                                      0: FlexColumnWidth(3),
                                      1: FlexColumnWidth(1),
                                      2: FlexColumnWidth(1),
                                      3: FlexColumnWidth(1),
                                    },
                                    children: [
                                      const TableRow(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 6.0,
                                              horizontal: 8.0,
                                            ),
                                            child: Text(
                                              'Barang',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 6.0,
                                              horizontal: 8.0,
                                            ),
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                'Qty',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 6.0,
                                              horizontal: 8.0,
                                            ),
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                'Harga',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 6.0,
                                              horizontal: 8.0,
                                            ),
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                'Subtotal',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      ...allItems.map(
                                        (it) => TableRow(
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 6.0,
                                                    horizontal: 8.0,
                                                  ),
                                              child: Text(it.namaBarang),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 6.0,
                                                    horizontal: 8.0,
                                                  ),
                                              child: Align(
                                                alignment:
                                                    Alignment.centerRight,
                                            child: Text(
                                              it.qty.toString(),
                                              maxLines: 1,
                                              softWrap: false,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 6.0,
                                                    horizontal: 8.0,
                                                  ),
                                              child: Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Text(
                                                  currency
                                                      .format(it.harga)
                                                      .replaceAll(
                                                          'Rp ', 'Rp\u00A0'),
                                                  maxLines: 1,
                                                  softWrap: false,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 6.0,
                                                    horizontal: 8.0,
                                                  ),
                                              child: Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Text(
                                                  currency
                                                      .format(it.subtotal)
                                                      .replaceAll(
                                                          'Rp ', 'Rp\u00A0'),
                                                  maxLines: 1,
                                                  softWrap: false,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            );
                          }
                          return const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        } else if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildBukuBesar() {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    if (_showAllBukuBesar) {
      return FutureBuilder<List<NeracaSaldoModel>>(
        future: _service.getNeracaSaldo(
          startDate: _startDate != null
              ? DateFormat('yyyy-MM-dd').format(_startDate!)
              : null,
          endDate: _endDate != null
              ? DateFormat('yyyy-MM-dd').format(_endDate!)
              : null,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final accounts = snapshot.data!
              .where(
                (n) => n.totalDebit != 0 || n.totalKredit != 0 || n.saldo != 0,
              )
              .toList();
          if (accounts.isEmpty) {
            return const Center(
              child: Text('Tidak ada akun dengan transaksi/saldo.'),
            );
          }
          return ListView(
            children: accounts.map((acc) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black.withOpacity(0.15)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ExpansionTile(
                  title: Text(
                    '${acc.kodeAkun} - ${acc.namaAkun}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  children: [
                    FutureBuilder<List<BukuBesarEntry>>(
                      future: _service.getBukuBesar(
                        acc.kodeAkun,
                        startDate: _startDate != null
                            ? DateFormat('yyyy-MM-dd').format(_startDate!)
                            : null,
                        endDate: _endDate != null
                            ? DateFormat('yyyy-MM-dd').format(_endDate!)
                            : null,
                      ),
                      builder: (context, bbSnapshot) {
                        if (bbSnapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              'Gagal memuat buku besar: ${bbSnapshot.error}',
                            ),
                          );
                        }
                        if (!bbSnapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(),
                          );
                        }
                        final entries = bbSnapshot.data!;
                        if (entries.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text('Tidak ada entri untuk akun ini.'),
                          );
                        }

                        List<TableRow> _rows(
                          List<BukuBesarEntry> list,
                          bool isDebit,
                        ) {
                          return list
                              .map(
                                (e) => TableRow(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6.0,
                                        horizontal: 0.0,
                                      ),
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              '${e.tanggal} - ${e.keterangan}',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          Expanded(
                                            child: Container(
                                              height: 1,
                                              color: Colors.black.withOpacity(
                                                0.15,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6.0,
                                        horizontal: 0.0,
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          currency.format(
                                            isDebit ? e.debit : e.kredit,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .toList();
                        }

                        double runningSaldo = 0;
                        final tableRows = <TableRow>[
                          const TableRow(
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 6.0,
                                  horizontal: 8.0,
                                ),
                                child: Text(
                                  'Tanggal - Uraian',
                                  maxLines: 1,
                                  softWrap: false,
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 6.0,
                                  horizontal: 8.0,
                                ),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'Debit',
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 6.0,
                                  horizontal: 8.0,
                                ),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'Kredit',
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 6.0,
                                  horizontal: 8.0,
                                ),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'Saldo',
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ];

                        for (final e in entries) {
                          runningSaldo += (e.debit - e.kredit);
                          tableRows.add(
                            TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6.0,
                                    horizontal: 0.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          '${e.tanggal} - ${e.keterangan}',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final double maxWidth = constraints.maxWidth;
                                          final double lineWidth = math.min(maxWidth * 0.25, 80);
                                          return SizedBox(
                                            width: lineWidth,
                                            child: Container(
                                              height: 1,
                                              color: Colors.black.withOpacity(0.12),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6.0,
                                    horizontal: 0.0,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(currency.format(e.debit)),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6.0,
                                    horizontal: 0.0,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(currency.format(e.kredit)),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6.0,
                                    horizontal: 0.0,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(currency.format(runningSaldo)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: IntrinsicWidth(
                            child: Table(
                              columnWidths: const {
                                0: FixedColumnWidth(360),
                                1: FixedColumnWidth(140),
                                2: FixedColumnWidth(140),
                                3: FixedColumnWidth(140),
                              },
                              children: tableRows,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      );
    }

    // Mode terpilih: gunakan set akun
    if (_selectedAkunSet.isEmpty) {
      return const Center(child: Text('Pilih akun pada dropdown filter'));
    }
    if (_selectedAkunSet.length > 1) {
      return FutureBuilder<List<NeracaSaldoModel>>(
        future: _service.getNeracaSaldo(
          startDate: _startDate != null
              ? DateFormat('yyyy-MM-dd').format(_startDate!)
              : null,
          endDate: _endDate != null
              ? DateFormat('yyyy-MM-dd').format(_endDate!)
              : null,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final accounts = snapshot.data!
              .where((n) => _selectedAkunSet.contains(n.kodeAkun))
              .toList();
          if (accounts.isEmpty) {
            return const Center(child: Text('Tidak ada akun terpilih.'));
          }
          return ListView(
            children: accounts.map((acc) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black.withOpacity(0.15)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ExpansionTile(
                  title: Text(
                    '${acc.kodeAkun} - ${acc.namaAkun}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  children: [
                    FutureBuilder<List<BukuBesarEntry>>(
                      future: _service.getBukuBesar(
                        acc.kodeAkun,
                        startDate: _startDate != null
                            ? DateFormat('yyyy-MM-dd').format(_startDate!)
                            : null,
                        endDate: _endDate != null
                            ? DateFormat('yyyy-MM-dd').format(_endDate!)
                            : null,
                      ),
                      builder: (context, bbSnapshot) {
                        if (bbSnapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              'Gagal memuat buku besar: ${bbSnapshot.error}',
                            ),
                          );
                        }
                        if (!bbSnapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(),
                          );
                        }
                        final entries = bbSnapshot.data!;
                        if (entries.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text('Tidak ada entri untuk akun ini.'),
                          );
                        }
                        List<TableRow> tableRows = [];
                        tableRows.add(
                          const TableRow(
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
                                child: Text(
                                  'Debit',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  'Kredit',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        );
                        for (final e in entries) {
                          tableRows.add(
                            TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(e.tanggal.toString()),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(e.keterangan),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(currency.format(e.debit)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(currency.format(e.kredit)),
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
                          },
                          children: tableRows,
                        );
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      );
    }
    final String akun = _selectedAkunSet.first;
    return FutureBuilder<List<BukuBesarEntry>>(
      future: _service.getBukuBesar(
        akun,
        startDate: _startDate != null
            ? DateFormat('yyyy-MM-dd').format(_startDate!)
            : null,
        endDate: _endDate != null
            ? DateFormat('yyyy-MM-dd').format(_endDate!)
            : null,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final entries = snapshot.data!;
        if (entries.isEmpty) {
          return const Center(
            child: Text('Tidak ada entri untuk akun terpilih.'),
          );
        }

        double runningSaldo = 0;

        return ListView(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const Text(
                    'Neraca Saldo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black.withOpacity(0.15)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(4),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(1),
                  },
                  children: [
                    const TableRow(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 6.0,
                            horizontal: 8.0,
                          ),
                          child: Text(
                            'Tanggal - Uraian',
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 6.0,
                            horizontal: 8.0,
                          ),
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
                          padding: EdgeInsets.symmetric(
                            vertical: 6.0,
                            horizontal: 8.0,
                          ),
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
                          padding: EdgeInsets.symmetric(
                            vertical: 6.0,
                            horizontal: 8.0,
                          ),
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
                    ),
                    ...entries.map((e) {
                      runningSaldo += (e.debit - e.kredit);
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6.0,
                              horizontal: 0.0,
                            ),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '${e.tanggal} - ${e.keterangan}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: Colors.black.withOpacity(0.15),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6.0,
                              horizontal: 0.0,
                            ),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(currency.format(e.debit)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6.0,
                              horizontal: 0.0,
                            ),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(currency.format(e.kredit)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6.0,
                              horizontal: 0.0,
                            ),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(currency.format(runningSaldo)),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNeracaSaldo() {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return FutureBuilder<List<NeracaSaldoModel>>(
      future: _service.getNeracaSaldo(
        startDate: _startDate != null
            ? DateFormat('yyyy-MM-dd').format(_startDate!)
            : null,
        endDate: _endDate != null
            ? DateFormat('yyyy-MM-dd').format(_endDate!)
            : null,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data!
            .where(
              (n) => n.totalDebit != 0 || n.totalKredit != 0 || n.saldo != 0,
            )
            .toList();
        if (items.isEmpty) {
          return const Center(
            child: Text('Tidak ada data neraca saldo non-nol.'),
          );
        }
        final totalDebit = items.fold<double>(
          0,
          (sum, n) => sum + n.totalDebit,
        );
        final totalKredit = items.fold<double>(
          0,
          (sum, n) => sum + n.totalKredit,
        );
        return ListView(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black.withOpacity(0.15)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: IntrinsicWidth(
                    child: Table(
                      columnWidths: const {
                        0: FixedColumnWidth(420),
                        1: FixedColumnWidth(160),
                        2: FixedColumnWidth(160),
                      },
                      children: [
                        const TableRow(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 6.0,
                                horizontal: 8.0,
                              ),
                              child: Text(
                                'Kode - Nama Akun',
                                maxLines: 1,
                                softWrap: false,
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 6.0,
                                horizontal: 8.0,
                              ),
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
                              padding: EdgeInsets.symmetric(
                                vertical: 6.0,
                                horizontal: 8.0,
                              ),
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
                          ],
                        ),
                        ...items.map(
                          (n) => TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6.0,
                                  horizontal: 8.0,
                                ),
                                child: Text(
                                  '${n.kodeAkun} - ${n.namaAkun}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6.0,
                                  horizontal: 8.0,
                                ),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(currency.format(n.totalDebit)),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6.0,
                                  horizontal: 8.0,
                                ),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(currency.format(n.totalKredit)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TableRow(
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 8.0,
                                horizontal: 8.0,
                              ),
                              child: Text(
                                'Total',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                                horizontal: 8.0,
                              ),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  currency.format(totalDebit),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                                horizontal: 8.0,
                              ),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  currency.format(totalKredit),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
