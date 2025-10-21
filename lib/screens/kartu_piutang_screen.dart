import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sia_mobile_soosvaldo/models/piutang_model.dart';
import 'package:sia_mobile_soosvaldo/models/kartu_piutang_model.dart';
import 'package:sia_mobile_soosvaldo/services/piutang_service.dart';

class KartuPiutangScreen extends StatefulWidget {
  const KartuPiutangScreen({super.key});

  @override
  State<KartuPiutangScreen> createState() => _KartuPiutangScreenState();
}

class _KartuPiutangScreenState extends State<KartuPiutangScreen> {
  final PiutangService _service = PiutangService();

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kartu Piutang')),
      body: FutureBuilder<List<PiutangModel>>(
        future: _service.getPiutang(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat piutang: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data!;
          // Tampilkan semua piutang (aktif maupun lunas)
          final Map<String, List<PiutangModel>> byCustomer = {};
          for (final p in list) {
            final key = (p.nikCustomer ?? '-') + '|' + (p.namaCustomer ?? '-');
            byCustomer.putIfAbsent(key, () => []).add(p);
          }
          if (byCustomer.isEmpty) {
            return const Center(child: Text('Tidak ada data piutang.'));
          }
          final entries = byCustomer.entries.toList()
            ..sort((a, b) => (a.key).compareTo(b.key));
          return ListView(
            children: entries.map((entry) {
              final parts = entry.key.split('|');
              final nik = parts.isNotEmpty ? parts[0] : '-';
              final nama = parts.length > 1 ? parts[1] : '-';
              final piutangs = entry.value;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black.withOpacity(0.15)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ExpansionTile(
                  title: Text('$nik - $nama', style: const TextStyle(fontWeight: FontWeight.w600)),
                  children: piutangs.map((p) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black.withOpacity(0.12)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ExpansionTile(
                        title: Text(
                          'Nota: ${p.kodeNota} | Tanggal: ${p.tanggal ?? '-'}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0, right: 8.0),
                          child: Wrap(
                            spacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text('Piutang Awal: ${_currency.format(p.total)}'),
                              Text('Sisa Piutang: ${_currency.format(p.sisa)}'),
                              // Indikator status
                              _buildStatusBadge(p.sisa > 0),
                            ],
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Histori Debit–Kredit (Running Balance)', style: TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 8),
                                FutureBuilder<List<KartuPiutangRow>>(
                                  future: _service.getKartuPiutangHistory(p.kodePiutang),
                                  builder: (context, hSnap) {
                                    if (hSnap.hasError) {
                                      return Text('Gagal memuat histori: ${hSnap.error}');
                                    }
                                    if (!hSnap.hasData) {
                                      return const LinearProgressIndicator();
                                    }
                                    final rowsData = hSnap.data!;
                                    final header = const TableRow(children: [
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
                                            'Sisa Piutang',
                                            maxLines: 1,
                                            softWrap: false,
                                            style: TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ),
                                    ]);

                                    final tableRows = <TableRow>[header];
                                    for (final r in rowsData) {
                                      tableRows.add(TableRow(children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Text(r.tanggal ?? '-'),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Text(
                                            r.keterangan,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(_currency.format(r.debit)),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(_currency.format(r.kredit)),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(_currency.format(r.saldo)),
                                          ),
                                        ),
                                      ]));
                                    }
                                    return SingleChildScrollView(
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
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          );
        },
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
}