import 'package:flutter/material.dart';

class MonthlyExpenseScreen extends StatelessWidget {
  const MonthlyExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('월지출')),
      body: const Center(child: Text('월지출 화면')),
    );
  }
}
