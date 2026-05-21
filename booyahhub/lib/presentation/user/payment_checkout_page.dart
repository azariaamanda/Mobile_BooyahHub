import 'package:flutter/material.dart';

class PaymentCheckoutPage extends StatelessWidget {
  final int pendaftaranId;
  const PaymentCheckoutPage({super.key, required this.pendaftaranId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Payment checkout page: pendaftaranId=$pendaftaranId')),
    );
  }
}

