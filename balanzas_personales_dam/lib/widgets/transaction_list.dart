import 'package:flutter/material.dart';
import '../models/transaction.dart';
import 'package:intl/intl.dart';

class TransactionList extends StatelessWidget {
  final List<Transaction> transactions;
  final Function(String) onDelete;
  final Function(Transaction) onEdit;

  TransactionList({
    required this.transactions,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return transactions.isEmpty
        ? Center(child: Text('Sin movimientos'))
        : ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (ctx, index) {
              final tx = transactions[index];
              final isIncome = tx.isIncome;
              final bgColor = isIncome ? Color(0xFF2C14DD) : Color(0xFFFF2D55);
              final icon = isIncome ? Icons.arrow_upward : Icons.arrow_downward;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (isIncome ? '+ ' : '- ') + '\$${tx.amount.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          Text(
                            DateFormat("d 'de' MMMM yyyy", 'es_ES').format(tx.date),
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => onEdit(tx),
                      icon: Icon(Icons.edit, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () => onDelete(tx.id),
                      icon: Icon(Icons.delete, color: Colors.white),
                    ),
                  ],
                ),
              );
            },
          );
  }
}
