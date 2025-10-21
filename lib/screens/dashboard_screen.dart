import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:sia_mobile_soosvaldo/screens/karyawan_list_screen.dart';
import 'package:sia_mobile_soosvaldo/screens/customer_list_screen.dart';
import 'package:sia_mobile_soosvaldo/screens/pos_screen.dart';
import 'package:sia_mobile_soosvaldo/screens/piutang_list_screen.dart';
import 'package:sia_mobile_soosvaldo/screens/membership_list_screen.dart';
import 'package:sia_mobile_soosvaldo/screens/barang_list_screen.dart';
import 'package:sia_mobile_soosvaldo/screens/accounting_screen.dart';
import 'package:sia_mobile_soosvaldo/services/piutang_service.dart';
import 'package:sia_mobile_soosvaldo/services/customer_service.dart';
import 'package:sia_mobile_soosvaldo/services/barang_service.dart';
import 'package:sia_mobile_soosvaldo/services/pos_service.dart';
import 'package:sia_mobile_soosvaldo/models/nota_jual_model.dart';
import 'package:sia_mobile_soosvaldo/models/piutang_model.dart';
import 'package:sia_mobile_soosvaldo/models/customer_model.dart';
import 'package:sia_mobile_soosvaldo/models/barang_model.dart';
import 'package:sia_mobile_soosvaldo/theme.dart';
import 'package:sia_mobile_soosvaldo/services/metrics_service.dart';
import 'package:sia_mobile_soosvaldo/models/metrics_model.dart';
import 'package:sia_mobile_soosvaldo/app_config.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PosService _posService = PosService();
  final PiutangService _piutangService = PiutangService();
  final CustomerService _customerService = CustomerService();
  final BarangService _barangService = BarangService();
  final MetricsService _metricsService = MetricsService();

  Timer? _autoRefreshTimer;
  final Duration _refreshInterval = const Duration(seconds: 10);

  double _monthlySales = 0;
  int _soonDueCount = 0;
  double _totalPiutangSisa = 0;
  int _customerCount = 0;
  int _stokTotal = 0;
  int _soldCount = 0;
  bool _loading = true;
  String _error = '';
  // Filter bulan untuk ringkasan penjualan
  String? _selectedMonth; // format: YYYY-MM

  @override
  void initState() {
    super.initState();
    _loadMetrics();
    _autoRefreshTimer = Timer.periodic(_refreshInterval, (_) {
      _loadMetrics();
    });
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final initial = _selectedMonth != null
        ? DateTime.parse('$_selectedMonth-01')
        : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5, 1),
      lastDate: DateTime(now.year + 1, 12),
      helpText: 'Pilih tanggal di bulan yang diinginkan',
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = DateFormat('yyyy-MM').format(picked);
        _loading = true;
      });
      await _loadMetrics();
    }
  }

  Future<void> _openMonthYearPicker() async {
    final now = DateTime.now();
    int initYear = _selectedMonth != null
        ? int.parse(_selectedMonth!.split('-')[0])
        : now.year;
    int initMonth = _selectedMonth != null
        ? int.parse(_selectedMonth!.split('-')[1])
        : now.month;

    int tempYear = initYear;
    int tempMonth = initMonth;
    final years = List<int>.generate(7, (i) => now.year - 5 + i);
    const monthLabels = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Pilih Bulan'),
          content: StatefulBuilder(
            builder: (ctx, setInner) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tahun'),
                    const SizedBox(height: 8),
                    DropdownButton<int>(
                      value: tempYear,
                      items: years
                          .map((y) => DropdownMenuItem<int>(
                                value: y,
                                child: Text('$y'),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setInner(() => tempYear = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('Bulan'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(12, (i) {
                        final m = i + 1;
                        final selected = m == tempMonth;
                        return ChoiceChip(
                          label: Text(monthLabels[i]),
                          selected: selected,
                          onSelected: (_) => setInner(() => tempMonth = m),
                        );
                      }),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedMonth =
                      '${tempYear}-${tempMonth.toString().padLeft(2, '0')}';
                  _loading = true;
                });
                _loadMetrics();
                Navigator.pop(ctx);
              },
              child: const Text('Pilih'),
            ),
          ],
        );
      },
    );
  }

  void _showSoldItemsDetail() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detail Barang Terjual',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: FutureBuilder(
                      future: _metricsService.getSoldItemsDetail(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text(snapshot.error.toString()));
                        }
                        final items = snapshot.data ?? [];
                        if (items.isEmpty) {
                          return const Center(
                            child: Text(
                              'Belum ada data barang terjual bulan ini',
                            ),
                          );
                        }
                        return ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final it = items[index];
                            return ListTile(
                              title: Text(it.namaBarang),
                              subtitle: Text('Kode: ${it.kodeBarang}'),
                              trailing: Text('${it.qty}'),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _loadMetrics() async {
    try {
      final DashboardMetrics metrics = await _metricsService
          .getDashboardMetrics(month: _selectedMonth);

      if (!mounted) return;
      setState(() {
        _monthlySales = metrics.monthlySales;
        _soonDueCount = metrics.soonDueCount;
        _totalPiutangSisa = metrics.totalPiutangSisa;
        _customerCount = metrics.customerCount;
        _stokTotal = metrics.stokTotal;
        _soldCount = metrics.soldCount;
        _loading = false;
        _error = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    String greetingText;
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      greetingText = 'Selamat Pagi';
    } else if (hour >= 12 && hour < 15) {
      greetingText = 'Selamat Siang';
    } else if (hour >= 15 && hour < 18) {
      greetingText = 'Selamat Sore';
    } else {
      greetingText = 'Selamat Malam';
    }
    final nama = AppConfig.namaKaryawan?.isNotEmpty == true
        ? AppConfig.namaKaryawan!
        : 'Pengguna';
    final items = [
      _MenuItem(
        'Point of Sale (POS)',
        Icons.shopping_cart,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PosScreen()),
        ),
      ),
      _MenuItem(
        'Karyawan',
        Icons.manage_accounts,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const KaryawanListScreen()),
        ),
      ),
      _MenuItem(
        'Customer',
        Icons.group,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CustomerListScreen()),
        ),
      ),
      _MenuItem(
        'Piutang',
        Icons.credit_card,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PiutangListScreen()),
        ),
      ),
      _MenuItem(
        'Membership',
        Icons.star,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MembershipListScreen()),
        ),
      ),
      _MenuItem(
        'Barang',
        Icons.archive,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BarangListScreen()),
        ),
      ),
      _MenuItem(
        'Riwayat Nota',
        Icons.history,
        () => Navigator.pushNamed(context, '/nota_jual'),
      ),
      _MenuItem(
        'Akuntansi',
        Icons.book,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AccountingScreen()),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greetingText, $nama',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Berikut Ringkasan Bisnis Anda Bulan Ini.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            // Kontrol filter bulan + kembali ke bulan ini
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _openMonthYearPicker,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Pilih Bulan'),
                ),
                if (_selectedMonth != null)
                  Text(
                    DateFormat('MM/yyyy').format(
                        DateTime.parse('${_selectedMonth!}-01')),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _selectedMonth = null);
                    _loadMetrics();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Kembali ke bulan ini'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Metrics: auto-adjust responsif menggunakan GridView shrinkWrap
            LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                // Ubah ke grid kolom tetap agar urutan kiri-kanan konsisten
                // mirip kotak-kotak menu POS/Karyawan/Customer.
                // Jadikan 2 kolom hanya di tablet/desktop agar HP tetap 1 kolom
                final int crossAxisCount = w >= 900 ? 2 : 1;
                // Tinggi kartu metrik di layar lebar sebelumnya terlalu pendek,
                // menyebabkan "BOTTOM OVERFLOWED". Turunkan childAspectRatio
                // agar tinggi tile bertambah pada desktop/tablet.
                // Di ponsel, kartu terasa terlalu tinggi. Tingkatkan rasio
                // aspek (width/height) agar tinggi berkurang dan tampil lebih
                // ramping. Di desktop tetap cukup tinggi agar tidak overflow.
                final double metricsAspect = w >= 1400
                    ? 2.6
                    : w >= 1200
                        ? 2.4
                        : w >= 900
                            ? 2.3
                            : w >= 600
                                ? 2.2
                                : w >= 480
                                    ? 2.8
                                    : w >= 360
                                        ? 3.2
                                        : 3.4;
                final metricWidgets = [
                  _MetricCard(
                    title: 'Penjualan',
                    value: _loading ? '...' : currency.format(_monthlySales),
                    subtitle: 'Bulanan',
                    icon: Icons.trending_up,
                    color: AppColors.success,
                  ),
                  _MetricCard(
                    title: 'Piutang',
                    value: _loading
                        ? '...'
                        : currency.format(_totalPiutangSisa),
                    subtitle: w < 380
                        ? 'Sisa total · JT: ${_soonDueCount}'
                        : 'Sisa total | Jatuh tempo: ${_soonDueCount}',
                    icon: Icons.credit_card,
                    color: AppColors.warning,
                  ),
                  _MetricCard(
                    title: 'Customer',
                    value: _loading ? '...' : _customerCount.toString(),
                    subtitle: 'Terdaftar',
                    icon: Icons.group,
                    color: AppColors.info,
                  ),
                  _MetricCard(
                    title: 'Barang Terjual',
                    value: _loading ? '...' : _soldCount.toString(),
                    subtitle: w < 380 ? 'Unit terjual' : 'Unit terjual bulan ini',
                    icon: Icons.sell,
                    color: AppColors.primary,
                    onTap: _showSoldItemsDetail,
                  ),
                ];
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    // Tinggi kartu cukup agar tiga baris konten tidak terpotong.
                    childAspectRatio: metricsAspect,
                  ),
                  itemCount: metricWidgets.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) => metricWidgets[index],
                );
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _showSoldItemsDetail,
                icon: const Icon(Icons.list),
                label: const Text('Lihat detail barang terjual'),
              ),
            ),
            const SizedBox(height: 16),
            // Menu grid: tetap responsif, tetapi ikut scroll parent (shrinkWrap)
            LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                // Breakpoints adaptif untuk grid menu: aman di ponsel, optimal di desktop
                final int crossAxisCount = w >= 1400
                    ? 6
                    : w >= 1200
                        ? 5
                        : w >= 992
                            ? 4
                            : w >= 768
                                ? 3
                                : 2;
                // Rasio aspek kartu untuk menjaga proporsi visual antar breakpoint
                final double menuAspect = w >= 1400
                    ? 1.4
                    : w >= 1200
                        ? 1.3
                        : w >= 992
                            ? 1.25
                            : w >= 768
                                ? 1.15
                                : 1.05;
                // Atur ukuran font label agar tetap satu baris pada layar kecil
                final TextStyle labelStyle = TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: w < 360
                      ? 12
                      : w < 480
                          ? 13
                          : 14,
                );
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: menuAspect,
                  children: items.map((item) {
                    // Pewarnaan ikon agar lebih hidup
                    final Color iconColor = () {
                      if (item.title.startsWith('Point of Sale'))
                        return AppColors.primary;
                      switch (item.title) {
                        case 'Karyawan':
                          return AppColors.success;
                        case 'Customer':
                          return AppColors.info;
                        case 'Piutang':
                          return AppColors.warning;
                        case 'Membership':
                          return AppColors.primaryLight;
                        case 'Barang':
                          return AppColors.primaryDark;
                        case 'Riwayat Nota':
                          return AppColors.info;
                        case 'Akuntansi':
                          return AppColors.primary;
                        default:
                          return AppColors.textPrimary;
                      }
                    }();
                    return CustomCard(
                      onTap: item.onTap,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(item.icon, size: 32, color: iconColor),
                          const SizedBox(height: 10),
                          // Pastikan label tetap satu baris; jika sempit, kecilkan font
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.title,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: labelStyle,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_error, style: const TextStyle(color: AppColors.danger)),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final double vPad = w < 360
        ? 10
        : w < 480
            ? 12
            : 16;
    final double boxSize = w < 360 ? 34 : 40;
    final double iconSize = w < 360 ? 26 : 32;
    return CustomCard(
      onTap: onTap,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: vPad),
      child: Row(
        children: [
          Container(
            width: boxSize,
            height: boxSize,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    fontSize: w < 360 ? 12 : null,
                  ),
                ),
                SizedBox(height: w < 360 ? 2 : 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                SizedBox(height: w < 360 ? 1 : 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: w < 360 ? 11 : 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  _MenuItem(this.title, this.icon, this.onTap);
}
