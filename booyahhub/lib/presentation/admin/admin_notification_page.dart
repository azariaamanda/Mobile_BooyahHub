import 'package:flutter/material.dart';

class AdminNotificationPage extends StatelessWidget {
  const AdminNotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
      ),
      body: const Center(
        child: Text('Halaman Notifikasi Admin'),
      ),
    );
  }
}
