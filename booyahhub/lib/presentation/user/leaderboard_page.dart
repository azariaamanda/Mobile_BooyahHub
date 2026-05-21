import 'package:flutter/material.dart';

class LeaderboardPage extends StatelessWidget {
  final int sesiId;
  const LeaderboardPage({super.key, required this.sesiId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Leaderboard page: sesiId=$sesiId')),
    );
  }
}

