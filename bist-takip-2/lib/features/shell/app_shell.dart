import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../distribution/distribution_page.dart';
import '../dividends/dividend_page.dart';
import '../history/history_page.dart';
import '../portfolio/portfolio_page.dart';
import '../settings/settings_page.dart';
import '../target/target_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      PortfolioPage(controller: widget.controller),
      DistributionPage(controller: widget.controller),
      DividendPage(controller: widget.controller),
      TargetPage(controller: widget.controller),
      HistoryPage(controller: widget.controller),
      SettingsPage(controller: widget.controller),
    ];

    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Portföy',
          ),
          NavigationDestination(
            icon: Icon(Icons.donut_large_outlined),
            label: 'Dağılım',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            label: 'Temettü',
          ),
          NavigationDestination(
            icon: Icon(Icons.track_changes_outlined),
            label: 'Hedef',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Geçmiş',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }
}
