// lib/presentation/admin/validate_payment_page.dart
//
// Catatan: layar daftar/verifikasi peserta kini berada di
// PesertaManagementPage (tab "Peserta" pada AdminMainNavigator).
//
// File ini dipertahankan hanya supaya route lama '/admin/verifikasi-pembayaran'
// di app_router.dart tetap valid. Isinya tinggal mendelegasikan ke
// PesertaManagementPage agar tidak ada kode ganda.

import 'package:flutter/material.dart';
import 'peserta_management_page.dart';

class ValidatePaymentPage extends StatelessWidget {
  const ValidatePaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dibungkus Scaffold karena dipakai sebagai halaman penuh lewat route,
    // bukan sebagai tab di dalam AdminMainNavigator.
    return const Scaffold(
      body: PesertaManagementPage(),
    );
  }
}
