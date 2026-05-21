import 'package:flutter/material.dart';

class BookingFormPage extends StatelessWidget {
  final int sesiId;
  const BookingFormPage({super.key, required this.sesiId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Booking form page: sesiId=$sesiId')),
    );
  }
}

