import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../widgets/transaction_list.dart';
import '../widgets/transaction_form.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Transaction> _userTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _addTransaction(Transaction transaction) {
    setState(() {
      _userTransactions.add(transaction);
    });
    _saveTransactions();
  }

  void _editTransaction(String id, Transaction newTransaction) {
    setState(() {
      final index = _userTransactions.indexWhere((tx) => tx.id == id);
      if (index != -1) {
        _userTransactions[index] = newTransaction;
      }
    });
    _saveTransactions();
  }

  void _deleteTransaction(String id) {
    setState(() {
      _userTransactions.removeWhere((tx) => tx.id == id);
    });
    _saveTransactions();
  }

  void _openTransactionForm([Transaction? existingTransaction]) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return TransactionForm(
          onSubmit:
              existingTransaction == null
                  ? _addTransaction
                  : (Transaction updatedTransaction) {
                    _editTransaction(
                      existingTransaction.id,
                      updatedTransaction,
                    );
                  },
          existingTransaction: existingTransaction,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mis Finanzas')),
      body: TransactionList(
        transactions: _userTransactions,
        onDelete: _deleteTransaction,
        onEdit: _openTransactionForm,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTransactionForm(),
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> txList =
        _userTransactions
            .map(
              (tx) => jsonEncode({
                'id': tx.id,
                'title': tx.title,
                'amount': tx.amount,
                'isIncome': tx.isIncome,
                'date': tx.date.toIso8601String(),
              }),
            )
            .toList();
    await prefs.setStringList('transactions', txList);
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final txList = prefs.getStringList('transactions') ?? [];

    setState(() {
      _userTransactions =
          txList.map((txString) {
            final data = jsonDecode(txString);
            return Transaction(
              id: data['id'],
              title: data['title'],
              amount: data['amount'],
              isIncome: data['isIncome'],
              date: DateTime.parse(data['date']),
            );
          }).toList();
    });
  }
}
