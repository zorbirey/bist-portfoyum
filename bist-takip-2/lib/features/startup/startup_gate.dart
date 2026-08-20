import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_controller.dart';
import '../shell/app_shell.dart';

class StartupGate extends StatefulWidget {
  const StartupGate({super.key, required this.controller});

  final AppController controller;

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  Uint8List? imageBytes;
  bool showSplash = true;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      final encoded =
          await rootBundle.loadString('assets/zeus_splash.b64');
      imageBytes = base64Decode(encoded.trim());
      if (mounted) setState(() {});
    } catch (_) {
      // Marka görseli yüklenemezse uygulama yine açılmalı.
    }

    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    setState(() => showSplash = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: showSplash
          ? Scaffold(
              key: const ValueKey('zeus-startup'),
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (imageBytes != null)
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 330,
                              maxHeight: 430,
                            ),
                            child: Image.memory(
                              imageBytes!,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                            ),
                          )
                        else
                          Icon(
                            Icons.bolt,
                            size: 88,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        const SizedBox(height: 18),
                        Text(
                          'BIST TAKİP 2.1',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'INSPIRED FROM ZEUS',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : AppShell(
              key: const ValueKey('app-shell'),
              controller: widget.controller,
            ),
    );
  }
}
