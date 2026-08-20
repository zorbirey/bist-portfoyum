import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/app_controller.dart';
import '../legacy/legacy_import_page.dart';
import '../shared/page_widgets.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.controller});

  final AppController controller;

  Future<void> _importLegacy(BuildContext context) async {
    final imported = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LegacyImportPage(controller: controller),
      ),
    );
    if (imported == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('1.1.5 yedeği 2.0 portföyüne aktarıldı.'),
        ),
      );
    }
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final now = DateTime.now();
    final initial = controller.portfolioStartDate ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: 'PORTFÖY BAŞLANGIÇ TARİHİ',
    );

    if (picked == null) return;
    await controller.updatePortfolioStartDate(picked);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Başlangıç tarihi ${DateFormat('dd.MM.yyyy').format(picked)} olarak kaydedildi.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final start = controller.portfolioStartDate;

        return PageFrame(
          title: 'Ayarlar',
          child: Column(
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text('Portföy başlangıç tarihi'),
                  subtitle: Text(
                    start == null
                        ? 'İlk alış işlemiyle otomatik oluşur. BIST 100, Dolar ve Altın kıyası için gereklidir.'
                        : '${DateFormat('dd.MM.yyyy').format(start)} · BIST 100, Dolar ve Altın bu tarihten bugüne kıyaslanır.',
                  ),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: () => _pickStartDate(context),
                ),
              ),
              const SizedBox(height: 10),
              const InfoCard(
                text:
                    '1.1.5 yedeğinde eski işlem tarihleri bulunmadığı için benchmark kıyası aktarım öncesini tam olarak yeniden oluşturamaz. Gerekirse başlangıç tarihini burada düzelt.',
                icon: Icons.timeline_outlined,
              ),
              const SizedBox(height: 10),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.restore),
                  title: const Text('1.1.5 yedeğini içe aktar'),
                  subtitle: const Text(
                    'Eski adet, maliyet ve hedefleri önce gösterir, onaydan sonra 2.0 açılış bakiyesine dönüştürür.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _importLegacy(context),
                ),
              ),
              const SizedBox(height: 10),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.compare_arrows_outlined),
                  title: Text('Karşılaştırma varlıkları'),
                  subtitle: Text(
                    'Portföy · BIST 100 · Dolar · Gram Altın',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.cloud_outlined),
                  title: Text('Bulut senkronizasyonu'),
                  subtitle: Text(
                    'Ticari sürüm altyapısı aşamasında eklenecek.',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.fingerprint),
                  title: Text('PIN / biyometri'),
                  subtitle: Text(
                    'Ticari sürüm güvenlik katmanında eklenecek.',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
