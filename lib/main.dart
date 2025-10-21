import 'package:flutter/material.dart';
import 'package:sia_mobile_soosvaldo/screens/login_screen.dart';
import 'package:sia_mobile_soosvaldo/screens/barang_list_screen.dart';
import 'package:sia_mobile_soosvaldo/screens/customer_list_screen.dart';
import 'package:sia_mobile_soosvaldo/screens/karyawan_list_screen.dart';
import 'package:sia_mobile_soosvaldo/screens/metode_pembayaran_list_screen.dart';
import 'package:sia_mobile_soosvaldo/screens/membership_list_screen.dart';
import 'package:sia_mobile_soosvaldo/screens/pos_screen.dart';
import 'package:sia_mobile_soosvaldo/screens/piutang_list_screen.dart';
import 'package:sia_mobile_soosvaldo/screens/accounting_screen.dart';
import 'package:sia_mobile_soosvaldo/screens/dashboard_screen.dart';
import 'package:sia_mobile_soosvaldo/screens/nota_jual_list_screen.dart';
import 'package:sia_mobile_soosvaldo/routes.dart';
import 'package:sia_mobile_soosvaldo/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIA Mobile Soosvaldo',
      theme: AppTheme.lightTheme,
      // Overlay kecil alias di kanan bawah semua screen
      builder: (context, child) {
        final base = child ?? const SizedBox.shrink();
        return Stack(
          children: [
            base,
            IgnorePointer(
              child: SafeArea(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Y.C',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withOpacity(0.45),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      initialRoute: '/login',
      navigatorObservers: [routeObserver],
      routes: {
        '/login': (context) => LoginScreen(),
        '/barang': (context) => BarangListScreen(),
        '/customer': (context) => CustomerListScreen(),
        '/karyawan': (context) => KaryawanListScreen(),
        '/metode_pembayaran': (context) => MetodePembayaranListScreen(),
        '/membership': (context) => MembershipListScreen(),
        '/pos': (context) => PosScreen(),
        '/piutang': (context) => PiutangListScreen(),
        '/accounting': (context) => AccountingScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/nota_jual': (context) => NotaJualListScreen(),
        // PaymentHistory screen removed to avoid duplication with Accounting/Nota Jual
      },
    );
  }
}

