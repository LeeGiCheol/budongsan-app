import 'package:flutter/material.dart';

class PdfExportScreen extends StatelessWidget {
  const PdfExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF 내보내기')),
      body: const Center(child: Text('PDF 내보내기 화면')),
    );
  }
}
