import 'package:flutter/material.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  static const pages = [
    _PortfolioPage(),
    _PlaceholderPage(title: 'Dağılım', message: 'Maliyet, güncel değer ve sektör dağılımları burada gösterilecek.'),
    _DividendPage(),
    _TargetPage(),
    _PlaceholderPage(title: 'Geçmiş', message: 'Günlük portföy değeri, BIST 100 kıyası ve gerçek getiri grafikleri burada olacak.'),
    _SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Portföy'),
          NavigationDestination(icon: Icon(Icons.donut_large_outlined), label: 'Dağılım'),
          NavigationDestination(icon: Icon(Icons.payments_outlined), label: 'Temettü'),
          NavigationDestination(icon: Icon(Icons.track_changes_outlined), label: 'Hedef'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Geçmiş'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Ayarlar'),
        ],
      ),
    );
  }
}

class _PageFrame extends StatelessWidget {
  const _PageFrame({required this.title, required this.child, this.subtitle});
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
        ],
        const SizedBox(height: 18),
        child,
      ],
    );
  }
}

class _PortfolioPage extends StatelessWidget {
  const _PortfolioPage();

  @override
  Widget build(BuildContext context) {
    return _PageFrame(
      title: 'BIST TAKİP 2.0',
      subtitle: 'Portföyün, gerçek getirilerin ve temettü gelirlerin tek yerde',
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(child: _MetricCard(label: 'PORTFÖY DEĞERİ', value: '— ₺')),
              SizedBox(width: 10),
              Expanded(child: _MetricCard(label: 'TOPLAM KÂR / ZARAR', value: '— ₺')),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(child: _MetricCard(label: 'BUGÜN', value: '— %')),
              SizedBox(width: 10),
              Expanded(child: _MetricCard(label: 'BIST 100 FARKI', value: '— %')),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('İşlem defteri', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text('2.0 ile portföy artık sadece adet ve ortalama maliyet tutmayacak. Her alış, satış, komisyon ve temettü ayrı işlem olarak kaydedilecek.'),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: null,
                      icon: Icon(Icons.add_chart),
                      label: Text('İLK İŞLEMİ EKLE'),
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

class _DividendPage extends StatelessWidget {
  const _DividendPage();

  @override
  Widget build(BuildContext context) {
    return const _PageFrame(
      title: 'Temettü',
      subtitle: 'Pasif gelirini ve gelecek ödemelerini takip et',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _MetricCard(label: 'BU YIL NET', value: '— ₺')),
              SizedBox(width: 10),
              Expanded(child: _MetricCard(label: 'AYLIK ORTALAMA', value: '— ₺')),
            ],
          ),
          SizedBox(height: 10),
          _MetricCard(label: 'TEMETTÜ MAAŞI HEDEFİ', value: '%0'),
          SizedBox(height: 16),
          _InfoCard(text: 'Yaklaşan temettüler, gerçekleşen ödemeler ve yeniden yatırım senaryoları bu merkezde toplanacak.'),
        ],
      ),
    );
  }
}

class _TargetPage extends StatelessWidget {
  const _TargetPage();

  @override
  Widget build(BuildContext context) {
    return const _PageFrame(
      title: 'Hedef',
      subtitle: 'Portföy ve temettü hedeflerini ayrı ayrı izle',
      child: Column(
        children: [
          _MetricCard(label: 'YILLIK NET TEMETTÜ HEDEFİ', value: '— ₺'),
          SizedBox(height: 10),
          _MetricCard(label: 'HEDEFE ULAŞMA', value: '%0'),
          SizedBox(height: 16),
          _InfoCard(text: 'Buradaki projeksiyonlar senaryo amaçlı olacak; gelecekteki getiri veya temettü garantisi olarak sunulmayacak.'),
        ],
      ),
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) {
    return _PageFrame(
      title: 'Ayarlar',
      child: Column(
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('1.1.5 yedeğini içe aktar'),
              subtitle: const Text('Eski adet, maliyet ve hedefleri 2.0 açılış bakiyesine dönüştürür.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 10),
          const Card(
            child: ListTile(
              leading: Icon(Icons.cloud_outlined),
              title: Text('Bulut senkronizasyonu'),
              subtitle: Text('Ticari sürüm altyapısı aşamasında eklenecek.'),
            ),
          ),
          const SizedBox(height: 10),
          const Card(
            child: ListTile(
              leading: Icon(Icons.fingerprint),
              title: Text('PIN / biyometri'),
              subtitle: Text('Ticari sürüm güvenlik katmanında eklenecek.'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => _PageFrame(title: title, child: _InfoCard(text: message));
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 7),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}
