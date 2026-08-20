import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_service.dart';
import 'mock_exam_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(const HmgsArenaApp());
}

class HmgsArenaApp extends StatelessWidget {
  const HmgsArenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HMGS ARENA',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7A263A)),
        useMaterial3: true,
      ),
      home: const HmgsArenaShell(),
    );
  }
}

class HmgsArenaShell extends StatefulWidget {
  const HmgsArenaShell({super.key});

  @override
  State<HmgsArenaShell> createState() => _HmgsArenaShellState();
}

class _HmgsArenaShellState extends State<HmgsArenaShell> {
  final AdService _adService = AdService();
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _adService.preload();
  }

  @override
  void dispose() {
    _adService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _ArenaHome(),
      const _StudyHome(),
      MockExamHomeScreen(adService: _adService),
      const _WeakTopicsHome(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield),
            label: 'Arena',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Çalışma',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'Denemeler',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Zayıf Konular',
          ),
        ],
      ),
    );
  }
}

class _ArenaHome extends StatelessWidget {
  const _ArenaHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HMGS ARENA')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.stadium_outlined,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PER ASPERA AD ASTRA',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                  ),
                  const SizedBox(height: 6),
                  const Text('Zorluklardan yıldızlara'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: ListTile(
              leading: Icon(Icons.local_fire_department_outlined),
              title: Text('Günlük Meydan Okuma'),
              subtitle: Text('Yeni sorular, seri ve XP sistemi için ana arena alanı.'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudyHome extends StatelessWidget {
  const _StudyHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Çalışma Modu')),
      body: const ListView(
        padding: EdgeInsets.all(20),
        children: [
          Card(
            child: ListTile(
              leading: Icon(Icons.balance_outlined),
              title: Text('Ders ve konu seç'),
              subtitle: Text('Çok Kolay, Kolay, Orta, Zor, Çok Zor veya dengeli rastgele çalışma.'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.repeat_outlined),
              title: Text('Tekrar koruması'),
              subtitle: Text('Yakın zamanda görülen sorular mümkün olduğunca tekrar gösterilmez.'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeakTopicsHome extends StatelessWidget {
  const _WeakTopicsHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zayıf Konular')),
      body: const ListView(
        padding: EdgeInsets.all(20),
        children: [
          Card(
            child: ListTile(
              leading: Icon(Icons.analytics_outlined),
              title: Text('Kişisel zayıf konu analizi'),
              subtitle: Text('Başarı oranı düşük ders ve konu başlıkları burada önceliklendirilir.'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.style_outlined),
              title: Text('Bilgi Kartları'),
              subtitle: Text('Yanlış sorunun aynısı yerine aynı konudan farklı sorular ve kısa konu kartları kullanılır.'),
            ),
          ),
        ],
      ),
    );
  }
}
