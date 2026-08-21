import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  static const navy = Color(0xFF03152B);
  static const gold = Color(0xFFFFD778);
  static const ice = Color(0xFF77CFFF);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HMGS ARENA',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: navy,
        colorScheme: const ColorScheme.dark(
          primary: gold,
          secondary: ice,
          surface: Color(0xFF0A2038),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        useMaterial3: true,
      ),
      home: const HmgsGate(),
    );
  }
}

class HmgsGate extends StatefulWidget {
  const HmgsGate({super.key});

  @override
  State<HmgsGate> createState() => _HmgsGateState();
}

class _HmgsGateState extends State<HmgsGate> {
  bool _entered = false;

  @override
  Widget build(BuildContext context) {
    if (_entered) return const HmgsArenaShell();
    return _EntryScreen(onEnter: () => setState(() => _entered = true));
  }
}

class _EntryScreen extends StatelessWidget {
  const _EntryScreen({required this.onEnter});

  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0B2B54), Color(0xFF010612)],
              ),
            ),
          ),
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/zeus_hmgs.svg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x14000000),
                    Color(0x14000000),
                    Color(0xAA010612),
                    Color(0xF0010612),
                  ],
                  stops: [0, .55, .78, 1],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: SizedBox(
                        width: 88,
                        height: 88,
                        child: SvgPicture.asset(
                          'assets/hmgs_arena_icon.svg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'HMGS ARENA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: HmgsArenaApp.gold,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                      shadows: [Shadow(color: Colors.black, blurRadius: 12)],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'PER ASPERA AD ASTRA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Zorluklardan yıldızlara',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: HmgsArenaApp.gold,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 62,
                    child: FilledButton(
                      onPressed: onEnter,
                      style: FilledButton.styleFrom(
                        backgroundColor: HmgsArenaApp.gold,
                        foregroundColor: const Color(0xFF07101C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'ARENAYA GİR',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
      const _RankingHome(),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _WatermarkBackground(),
          IndexedStack(index: _index, children: pages),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 66,
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 6),
          decoration: BoxDecoration(
            color: const Color(0xF206192D),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x3377CFFF)),
          ),
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: (value) => setState(() => _index = value),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: HmgsArenaApp.gold,
            unselectedItemColor: const Color(0xFF8EA8C1),
            selectedFontSize: 11,
            unselectedFontSize: 10,
            iconSize: 22,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Arena'),
              BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Çalışma'),
              BottomNavigationBarItem(icon: Icon(Icons.timer_rounded), label: 'Deneme'),
              BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Zayıf'),
              BottomNavigationBarItem(icon: Icon(Icons.emoji_events_rounded), label: 'Sıralama'),
            ],
          ),
        ),
      ),
    );
  }
}

class _WatermarkBackground extends StatelessWidget {
  const _WatermarkBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF082B50), Color(0xFF020916)],
              ),
            ),
          ),
          Center(
            child: Opacity(
              opacity: 0.12,
              child: FractionallySizedBox(
                widthFactor: .92,
                heightFactor: .92,
                child: SvgPicture.asset(
                  'assets/zeus_hmgs.svg',
                  fit: BoxFit.contain,
                ),
              ),
            ),
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
    return const _TransparentPage(
      title: 'HMGS ARENA',
      showBrand: true,
      children: [
        _GlassCard(
          icon: Icons.bolt_rounded,
          title: 'PER ASPERA AD ASTRA',
          subtitle: 'Zorluklardan yıldızlara',
        ),
        _GlassCard(
          icon: Icons.local_fire_department_rounded,
          title: 'Günlük Meydan Okuma',
          subtitle: 'Yeni sorular, seri ve XP sistemi için ana arena alanı.',
        ),
      ],
    );
  }
}

class _StudyHome extends StatelessWidget {
  const _StudyHome();

  @override
  Widget build(BuildContext context) {
    return const _TransparentPage(
      title: 'Çalışma Modu',
      children: [
        _GlassCard(
          icon: Icons.balance_rounded,
          title: 'Ders ve konu seç',
          subtitle: 'Çok Kolay, Kolay, Orta, Zor, Çok Zor veya dengeli rastgele çalışma.',
        ),
        _GlassCard(
          icon: Icons.repeat_rounded,
          title: 'Tekrar koruması',
          subtitle: 'Yakın zamanda görülen sorular mümkün olduğunca tekrar gösterilmez.',
        ),
      ],
    );
  }
}

class _WeakTopicsHome extends StatelessWidget {
  const _WeakTopicsHome();

  @override
  Widget build(BuildContext context) {
    return const _TransparentPage(
      title: 'Zayıf Konular',
      children: [
        _GlassCard(
          icon: Icons.analytics_rounded,
          title: 'Kişisel zayıf konu analizi',
          subtitle: 'Başarı oranı düşük ders ve konu başlıkları burada önceliklendirilir.',
        ),
        _GlassCard(
          icon: Icons.style_rounded,
          title: 'Bilgi Kartları',
          subtitle: 'Yanlış sorunun aynısı yerine aynı konudan farklı sorular ve kısa konu kartları kullanılır.',
        ),
      ],
    );
  }
}

class _RankingHome extends StatelessWidget {
  const _RankingHome();

  @override
  Widget build(BuildContext context) {
    return const _TransparentPage(
      title: 'Sıralama',
      children: [
        _GlassCard(
          icon: Icons.emoji_events_rounded,
          title: 'Arena Sıralaması',
          subtitle: 'Puan, seri ve deneme performansına göre sıralama alanı.',
        ),
      ],
    );
  }
}

class _TransparentPage extends StatelessWidget {
  const _TransparentPage({
    required this.title,
    required this.children,
    this.showBrand = false,
  });

  final String title;
  final List<Widget> children;
  final bool showBrand;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 92),
        children: [
          if (showBrand) ...[
            Center(
              child: SizedBox(
                width: 108,
                height: 108,
                child: SvgPicture.asset('assets/hmgs_arena_icon.svg'),
              ),
            ),
            const SizedBox(height: 18),
          ],
          ...children.expand((w) => [w, const SizedBox(height: 14)]),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xD90B223B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0x2877CFFF)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        leading: Icon(icon, color: HmgsArenaApp.gold, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(subtitle),
        ),
      ),
    );
  }
}
