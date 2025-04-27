import 'package:flutter/material.dart';
import '../models/transaction.dart';

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
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: tx.isIncome ? Colors.green : Colors.red,
                  child: Icon(
                    tx.isIncome ? Icons.add : Icons.remove,
                    color: Colors.white,
                  ),
                ),
                title: Text(tx.title),
                subtitle: Text('\$${tx.amount.toStringAsFixed(2)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => onEdit(tx),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.grey),
                      onPressed: () => onDelete(tx.id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
  }
}
