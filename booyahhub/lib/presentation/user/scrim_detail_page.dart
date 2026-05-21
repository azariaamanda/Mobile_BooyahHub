import 'package:flutter/material.dart';

class ScrimDetailPage extends StatelessWidget {
  final int scrimId;
  const ScrimDetailPage({super.key, required this.scrimId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Scrim detail page: scrimId=$scrimId')),
    );
  }
}

