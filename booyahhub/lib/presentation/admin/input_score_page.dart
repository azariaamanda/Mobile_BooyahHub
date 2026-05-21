import 'package:flutter/material.dart';

class InputScorePage extends StatelessWidget {
  final int sesiId;
  const InputScorePage({super.key, required this.sesiId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Input score page: sesiId=$sesiId')),
    );
  }
}

