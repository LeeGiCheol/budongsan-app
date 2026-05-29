import 'package:flutter/material.dart';

class LoanCalculatorScreen extends StatelessWidget {
  const LoanCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('대출계산')),
      body: const Center(child: Text('대출계산 화면')),
    );
  }
}
