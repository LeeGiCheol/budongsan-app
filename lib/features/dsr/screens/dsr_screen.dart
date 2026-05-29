import 'package:flutter/material.dart';

class DsrScreen extends StatelessWidget {
  const DsrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DSR 계산')),
      body: const Center(child: Text('DSR 계산 화면')),
    );
  }
}
