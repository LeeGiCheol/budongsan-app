import 'package:flutter/material.dart';

class CashFlowScreen extends StatelessWidget {
  const CashFlowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('현금흐름')),
      body: const Center(child: Text('현금흐름 화면')),
    );
  }
}
