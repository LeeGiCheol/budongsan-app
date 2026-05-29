import 'package:flutter/material.dart';

class AcquisitionTaxScreen extends StatelessWidget {
  const AcquisitionTaxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('취득세 계산')),
      body: const Center(child: Text('취득세 계산 화면')),
    );
  }
}
