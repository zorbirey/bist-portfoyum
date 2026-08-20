import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app_controller.dart';
import 'app/app_theme.dart';
import 'data/benchmarks/benchmark_feed.dart';
import 'data/dividends/dividend_feed.dart';
import 'data/local/local_portfolio_store.dart';
import 'data/market/market_feed.dart';
import 'features/startup/startup_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');

  final controller = AppController(
    store: LocalPortfolioStore(),
    marketFeed: const GithubJsonMarketFeed(),
    dividendFeed: const GithubJsonDividendFeed(),
    benchmarkFeed: const YahooPrototypeBenchmarkFeed(),
  );
  await controller.load();

  runApp(BistTakipApp(controller: controller));

  controller.refreshMarket();
  controller.refreshDividends();
  controller.refreshBenchmarks();
}

class BistTakipApp extends StatelessWidget {
  const BistTakipApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BIST TAKİP 2.1',
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [
        Locale('tr', 'TR'),
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.light,
      home: StartupGate(controller: controller),
    );
  }
}
