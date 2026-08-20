import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../data/legacy/legacy_backup_migrator.dart';

class LegacyImportPage extends StatefulWidget {
  const LegacyImportPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<LegacyImportPage> createState() => _LegacyImportPageState();
}

class _LegacyImportPageState extends State<LegacyImportPage> {
  final migrator = const LegacyBackupMigrator();

  LegacyMigrationResult? preview;
  String? fileName;
  String? error;
  bool importing = false;

  Future<void> _pickFile() async {
    setState(() {
      error = null;
      preview = null;
      fileName = null;
    });

    try {
      final selection = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      if (selection == null) return;

      final file = selection.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        throw const FormatException('Dosya içeriği okunamadı.');
      }

      final rawJson = utf8.decode(bytes);
      final result = migrator.migrate(rawJson);
      if (!mounted) return;
      setState(() {
        fileName = file.name;
        preview = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(
        () => error =
            'Yedek açılamadı. 1.1.5 tarafından oluşturulmuş .json dosyasını seç. (${e.toString()})',
      );
    }
  }

  Future<void> _import() async {
    final result = preview;
    if (result == null) return;

    if (widget.controller.transactions.isNotEmpty) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Mevcut 2.0 verileri değiştirilsin mi?'),
          content: const Text(
            'İçe aktarma mevcut 2.0 işlem kayıtlarının yerine 1.1.5 yedeğindeki açılış pozisyonlarını yazacak. Yedek dosyanın kendisi değiştirilmeyecek.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('VAZGEÇ'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('DEVAM ET'),
            ),
          ],
        ),
      );
      if (replace != true) return;
    }

    setState(() => importing = true);
    await widget.controller.importLegacy(result);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  String _money(double value) =>
      value.toStringAsFixed(2).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    final result = preview;

    return Scaffold(
      appBar: AppBar(title: const Text('1.1.5 Yedeğini İçe Aktar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Eski yedek dosyası yalnızca okunur. 1.1.5 dosyan silinmez veya değiştirilmez. Eski alış/satış tarihleri yedekte bulunmadığı için pozisyonlar 2.0 başlangıç bakiyesi olarak aktarılır.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: importing ? null : _pickFile,
            icon: const Icon(Icons.folder_open_outlined),
            label: const Text('JSON YEDEK DOSYASINI SEÇ'),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (result != null) ...[
            const SizedBox(height: 16),
            Text(
              'Aktarım önizlemesi',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(fileName ?? 'Yedek dosyası'),
                    subtitle:
                        Text('${result.transactions.length} pozisyon bulundu'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Yıllık temettü hedefi'),
                    trailing: Text('${_money(result.annualTarget)} ₺'),
                  ),
                  ListTile(
                    title: const Text('Aylık temettü hedefi'),
                    trailing: Text('${_money(result.monthlyTarget)} ₺'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ...result.transactions.map(
              (tx) => Card(
                child: ListTile(
                  title: Text(
                    tx.ticker,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${tx.quantity.toStringAsFixed(2)} adet · Ort. maliyet ${_money(tx.unitPrice)} ₺',
                  ),
                  trailing: const Icon(Icons.check_circle_outline),
                ),
              ),
            ),
            if (result.warnings.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...result.warnings.map(
                (warning) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(warning),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: importing ? null : _import,
              icon: importing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.system_update_alt_outlined),
              label: Text(importing ? 'AKTARILIYOR' : 'YEDEĞİ 2.0’A AKTAR'),
            ),
          ],
        ],
      ),
    );
  }
}
