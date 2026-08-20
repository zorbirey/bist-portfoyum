import 'package:flutter/material.dart';
import 'app/app_theme.dart';
import 'features/shell/app_shell.dart';

void main() {
  runApp(const BistTakipApp());
}

class BistTakipApp extends StatelessWidget {
  const BistTakipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BIST TAKİP 2.0',
      theme: AppTheme.light,
      home: const AppShell(),
    );
  }
}
