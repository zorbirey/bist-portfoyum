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
    const navy = Color(0xFF03152B);
    const gold = Color(0xFFFFD778);
    const ice = Color(0xFF77CFFF);

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
    const gold = Color(0xFFFFD778);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF08214A), Color(0xFF010714)],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    const _ArenaBrandMark(size: 170, showRings: false),
                    const SizedBox(height: 24),
                    const Text(
                      'HMGS',
                      style: TextStyle(
                        color: gold,
                        fontSize: 56,
                        height: 0.95,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                    const Text(
                      'ARENA',
                      style: TextStyle(
                        color: gold,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'PER ASPERA AD ASTRA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'ZORLUKLARDAN YILDIZLARA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: gold,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF2D73B7), width: 3),
                      ),
                      child: const Center(
                        child: Icon(Icons.bolt, color: gold, size: 120),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 66,
                      child: OutlinedButton(
                        onPressed: onEnter,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: gold,
                          side: const BorderSide(color: gold, width: 3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'ARENAYA GİR',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            );
          },
        ),
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _WatermarkBackground(),
          IndexedStack(index: _index, children: pages),
        ],
      ),
      bottomNavigationBar: SizedBox(
        height: 72,
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (value) => setState(() => _index = value),
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF06192D),
          selectedItemColor: const Color(0xFFFFD778),
          unselectedItemColor: const Color(0xFF8EA8C1),
          selectedFontSize: 12,
          unselectedFontSize: 11,
          iconSize: 24,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Arena'),
            BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Çalışma'),
            BottomNavigationBarItem(icon: Icon(Icons.timer_rounded), label: 'Deneme'),
            BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Zayıf'),
            BottomNavigationBarItem(icon: Icon(Icons.emoji_events_rounded), label: 'Sıralama'),
          ],
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
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF082B50), Color(0xFF020916)],
          ),
        ),
        child: const Center(
          child: Opacity(
            opacity: 0.10,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'HMGS ARENA',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
                SizedBox(height: 12),
                Text(
                  'INSPIRED FROM',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 4),
                ),
                Text(
                  'ZEUS',
                  style: TextStyle(fontSize: 60, fontWeight: FontWeight.w900, letterSpacing: 3),
                ),
                SizedBox(height: 12),
                _ArenaBrandMark(size: 260, showRings: true),
                SizedBox(height: 24),
                Text(
                  'GÜÇ · MİRAS · ARENA',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
                Text(
                  'HMGS ARENA',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArenaBrandMark extends StatelessWidget {
  const _ArenaBrandMark({required this.size, required this.showRings});

  final double size;
  final bool showRings;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ArenaBrandPainter(showRings: showRings)),
    );
  }
}

class _ArenaBrandPainter extends CustomPainter {
  const _ArenaBrandPainter({required this.showRings});

  final bool showRings;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final s = size.shortestSide;
    final blue = Paint()
      ..color = const Color(0xFF68CFFF)
      ..strokeWidth = s * 0.018
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final gold = Paint()..color = const Color(0xFFFFD778);
    final darkGold = Paint()..color = const Color(0xFF70420C);

    if (showRings) {
      final ring = Paint()
        ..color = const Color(0xFF68CFFF)
        ..strokeWidth = s * 0.012
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(c, s * 0.32, ring);
      canvas.drawCircle(c, s * 0.39, ring);
    }

    final left = Path()
      ..moveTo(s * 0.12, s * 0.18)
      ..lineTo(s * 0.22, s * 0.34)
      ..lineTo(s * 0.17, s * 0.53)
      ..lineTo(s * 0.26, s * 0.72);
    final right = Path()
      ..moveTo(s * 0.88, s * 0.18)
      ..lineTo(s * 0.78, s * 0.34)
      ..lineTo(s * 0.83, s * 0.53)
      ..lineTo(s * 0.74, s * 0.72);
    canvas.drawPath(left, blue);
    canvas.drawPath(right, blue);

    final crest = Path()
      ..moveTo(s * 0.36, s * 0.22)
      ..lineTo(s * 0.64, s * 0.22)
      ..lineTo(s * 0.60, s * 0.36)
      ..lineTo(s * 0.68, s * 0.42)
      ..lineTo(s * 0.62, s * 0.70)
      ..lineTo(s * 0.50, s * 0.79)
      ..lineTo(s * 0.38, s * 0.70)
      ..lineTo(s * 0.32, s * 0.42)
      ..lineTo(s * 0.40, s * 0.36)
      ..close();
    canvas.drawPath(crest, gold);

    final face = Path()
      ..moveTo(s * 0.50, s * 0.37)
      ..lineTo(s * 0.61, s * 0.45)
      ..lineTo(s * 0.59, s * 0.60)
      ..lineTo(s * 0.50, s * 0.67)
      ..lineTo(s * 0.41, s * 0.60)
      ..lineTo(s * 0.39, s * 0.45)
      ..close();
    canvas.drawPath(face, darkGold);

    final eye = Paint()..color = const Color(0xFF07101C);
    final leftEye = Path()
      ..moveTo(s * 0.405, s * 0.51)
      ..lineTo(s * 0.485, s * 0.53)
      ..lineTo(s * 0.44, s * 0.56)
      ..close();
    final rightEye = Path()
      ..moveTo(s * 0.595, s * 0.51)
      ..lineTo(s * 0.515, s * 0.53)
      ..lineTo(s * 0.56, s * 0.56)
      ..close();
    canvas.drawPath(leftEye, eye);
    canvas.drawPath(rightEye, eye);
  }

  @override
  bool shouldRepaint(covariant _ArenaBrandPainter oldDelegate) => oldDelegate.showRings != showRings;
}

class _ArenaHome extends StatelessWidget {
  const _ArenaHome();

  @override
  Widget build(BuildContext context) {
    return _TransparentPage(
      title: 'HMGS ARENA',
      children: const [
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
  const _TransparentPage({required this.title, required this.children});

  final String title;
  final List<Widget> children;

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
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 12),
          ...children.expand((w) => [w, const SizedBox(height: 14)]),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xCC0B223B),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        leading: Icon(icon, color: const Color(0xFFFFD778), size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(subtitle),
        ),
      ),
    );
  }
}
