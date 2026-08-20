import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../domain/models/portfolio_transaction.dart';

class TransactionFormPage extends StatefulWidget {
  const TransactionFormPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends State<TransactionFormPage> {
  final tickerController = TextEditingController();
  final quantityController = TextEditingController();
  final priceController = TextEditingController();
  final feeController = TextEditingController(text: '0');
  final dividendController = TextEditingController();
  final noteController = TextEditingController();

  PortfolioTransactionType type = PortfolioTransactionType.buy;
  DateTime date = DateTime.now();
  bool saving = false;
  String? error;

  @override
  void dispose() {
    tickerController.dispose();
    quantityController.dispose();
    priceController.dispose();
    feeController.dispose();
    dividendController.dispose();
    noteController.dispose();
    super.dispose();
  }

  double _number(String input) {
    var text = input.trim().replaceAll(' ', '');
    if (text.contains(',')) {
      text = text.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(text) ?? 0;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => date = picked);
  }

  Future<void> _save() async {
    final ticker = tickerController.text.trim().toUpperCase();
    final quantity = _number(quantityController.text);
    final price = _number(priceController.text);
    final fee = _number(feeController.text);
    final dividend = _number(dividendController.text);

    if (ticker.isEmpty) {
      setState(() => error = 'Hisse kodunu gir.');
      return;
    }

    if (type == PortfolioTransactionType.dividend) {
      if (dividend <= 0) {
        setState(() => error = 'Net temettü tutarını gir.');
        return;
      }
    } else {
      if (quantity <= 0 || price <= 0) {
        setState(() => error = 'Adet ve işlem fiyatı sıfırdan büyük olmalı.');
        return;
      }
      if (type == PortfolioTransactionType.sell) {
        final available = widget.controller.holdings[ticker]?.quantity ?? 0;
        if (quantity > available) {
          setState(
            () => error =
                'Satılabilir adet ${available.toStringAsFixed(2)}. Daha fazla satış kaydedilemez.',
          );
          return;
        }
      }
    }

    setState(() {
      saving = true;
      error = null;
    });

    final transaction = PortfolioTransaction(
      id: 'tx-${DateTime.now().microsecondsSinceEpoch}',
      ticker: ticker,
      type: type,
      date: date,
      quantity: type == PortfolioTransactionType.dividend ? 0 : quantity,
      unitPrice: type == PortfolioTransactionType.dividend ? 0 : price,
      fee: type == PortfolioTransactionType.dividend ? 0 : fee,
      netDividend:
          type == PortfolioTransactionType.dividend ? dividend : 0,
      note: noteController.text.trim().isEmpty
          ? null
          : noteController.text.trim(),
    );

    await widget.controller.addTransaction(transaction);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final quote =
        widget.controller.quoteFor(tickerController.text.trim().toUpperCase());

    return Scaffold(
      appBar: AppBar(title: const Text('İşlem Ekle')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<PortfolioTransactionType>(
            value: type,
            decoration: const InputDecoration(labelText: 'İşlem türü'),
            items: const [
              DropdownMenuItem(
                value: PortfolioTransactionType.buy,
                child: Text('Alış'),
              ),
              DropdownMenuItem(
                value: PortfolioTransactionType.sell,
                child: Text('Satış'),
              ),
              DropdownMenuItem(
                value: PortfolioTransactionType.dividend,
                child: Text('Temettü'),
              ),
            ],
            onChanged: saving
                ? null
                : (value) => setState(
                      () => type = value ?? PortfolioTransactionType.buy,
                    ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: tickerController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'BIST kodu',
              hintText: 'TUPRS',
              helperText: quote == null
                  ? 'Kod girildiğinde mevcut fiyat kaynağıyla eşleşir.'
                  : '${quote.name} · ${quote.price.toStringAsFixed(2)} ₺',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          if (type != PortfolioTransactionType.dividend) ...[
            TextField(
              controller: quantityController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Hisse adedi'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'İşlem fiyatı',
                suffixText: '₺',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: feeController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Komisyon / masraf',
                suffixText: '₺',
              ),
            ),
          ] else ...[
            TextField(
              controller: dividendController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Net temettü tutarı',
                suffixText: '₺',
              ),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: saving ? null : _pickDate,
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(
              '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Not',
              hintText: 'İsteğe bağlı',
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: saving ? null : _save,
            icon: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(saving ? 'KAYDEDİLİYOR' : 'İŞLEMİ KAYDET'),
          ),
        ],
      ),
    );
  }
}
