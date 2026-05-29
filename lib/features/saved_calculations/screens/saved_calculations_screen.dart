import 'package:flutter/material.dart';

class SavedCalculationsScreen extends StatelessWidget {
  const SavedCalculationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('저장된 계산')),
      body: const Center(child: Text('저장된 계산 화면')),
    );
  }
}
