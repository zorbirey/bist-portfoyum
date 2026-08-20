import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/app_controller.dart';
import '../../domain/models/portfolio_transaction.dart';

class TransactionHistoryPage extends StatelessWidget {
  const TransactionHistoryPage({super.key, required this.controller});

  final AppController controller;

  String _type(PortfolioTransactionType type) => switch (type) {
        PortfolioTransactionType.opening => 'AÇILIŞ',
        PortfolioTransactionType.buy => 'ALIŞ',
        PortfolioTransactionType.sell => 'SATIŞ',
        PortfolioTransactionType.dividend => 'TEMETTÜ',
      };

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy', 'tr_TR');
    final money = NumberFormat('#,##0.00', 'tr_TR');

    return Scaffold(
      appBar: AppBar(title: const Text('İşlem Geçmişi')),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final transactions = controller.transactions;
          if (transactions.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Henüz alış, satış veya temettü işlemi yok.'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final isDividend =
                  tx.type == PortfolioTransactionType.dividend;
              final detail = isDividend
                  ? 'Gerçek net ${money.format(tx.netDividend)} ₺'
                  : '${money.format(tx.quantity)} adet · ${money.format(tx.unitPrice)} ₺ · Masraf ${money.format(tx.fee)} ₺';

              return Card(
                child: ListTile(
                  title: Text(
                    '${tx.ticker} · ${_type(tx.type)}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${dateFormat.format(tx.date)}\n$detail${tx.note == null ? '' : '\n${tx.note}'}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    tooltip: 'İşlemi sil',
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('İşlem silinsin mi?'),
                          content: Text(
                            '${tx.ticker} ${_type(tx.type).toLowerCase()} kaydı silinecek ve portföy yeniden hesaplanacak.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: const Text('VAZGEÇ'),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              child: const Text('SİL'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await controller.deleteTransaction(tx.id);
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
