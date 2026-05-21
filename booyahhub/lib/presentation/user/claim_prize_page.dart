import 'package:flutter/material.dart';

class ClaimPrizePage extends StatelessWidget {
  final int pendaftaranId;
  const ClaimPrizePage({super.key, required this.pendaftaranId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Claim prize page: pendaftaranId=$pendaftaranId')),
    );
  }
}

