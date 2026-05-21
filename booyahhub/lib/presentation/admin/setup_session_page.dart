import 'package:flutter/material.dart';

class SetupSessionPage extends StatelessWidget {
  final int scrimId;
  const SetupSessionPage({super.key, required this.scrimId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Setup session page: scrimId=$scrimId')),
    );
  }
}

