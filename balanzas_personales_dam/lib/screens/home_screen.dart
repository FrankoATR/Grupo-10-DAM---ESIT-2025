import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../widgets/transaction_list.dart';
import '../widgets/transaction_form.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Transaction> _userTransactions = [];
  int _currentIndex = 0;
  String _filterType = 'Todo';
  String _sortOrder = 'Reciente';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> clearAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: TransactionForm(
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
            ),
          ),
        );
      },
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

  @override
  Widget build(BuildContext context) {
    List<Transaction> filteredTransactions =
        _userTransactions.where((tx) {
          if (_filterType == 'Entrada') return tx.isIncome;
          if (_filterType == 'Salida') return !tx.isIncome;
          return true;
        }).toList();

    filteredTransactions.sort((a, b) {
      if (_sortOrder == 'Reciente') {
        return b.date.compareTo(a.date);
      } else {
        return a.date.compareTo(b.date);
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          const Center(
            child: Text(
              'Finanzas de ROSA',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.deepPurple),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Historial de finanzas',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Mostrar:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C14DD),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Wrap(
                        spacing: 10,
                        children: [
                          FilterChip(
                            label: Text('Entrada'),
                            selected: _filterType == 'Entrada',
                            onSelected:
                                (_) => setState(() => _filterType = 'Entrada'),
                          ),
                          FilterChip(
                            label: Text('Salida'),
                            selected: _filterType == 'Salida',
                            onSelected:
                                (_) => setState(() => _filterType = 'Salida'),
                          ),
                          FilterChip(
                            label: Text('Todo'),
                            selected: _filterType == 'Todo',
                            onSelected:
                                (_) => setState(() => _filterType = 'Todo'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
  
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Ordenar por:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C14DD),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Wrap(
                        spacing: 10,
                        children: [
                          ChoiceChip(
                            label: Text('Reciente'),
                            selected: _sortOrder == 'Reciente',
                            onSelected:
                                (_) => setState(() => _sortOrder = 'Reciente'),
                          ),
                          ChoiceChip(
                            label: Text('Antiguo'),
                            selected: _sortOrder == 'Antiguo',
                            onSelected:
                                (_) => setState(() => _sortOrder = 'Antiguo'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: TransactionList(
              transactions: filteredTransactions,
              onDelete: _deleteTransaction,
              onEdit: _openTransactionForm,
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
        child: SizedBox(
          width: 70,
          height: 70,
          child: FloatingActionButton(
            onPressed: () => _openTransactionForm(),
            backgroundColor: Color(0xFF007AFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 32),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
