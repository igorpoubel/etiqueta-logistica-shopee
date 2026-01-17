import 'package:flutter/material.dart';
import 'dual_printer_screen.dart'; // Importe o arquivo da sua tela

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Impressão Dual',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const DualPrinterScreen(),
    );
  }
}
