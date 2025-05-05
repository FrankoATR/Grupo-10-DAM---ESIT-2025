import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../widgets/transaction_list.dart';
import '../widgets/transaction_form.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/confirmation_dialog.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import '../utils/cryp.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTransactions();
    });
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

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) {
        return ConfirmationDialog(
          title: 'Eliminar dato',
          message: '¿Estás seguro de que deseas eliminar este dato?',
          onConfirm: () => _deleteTransaction(id),
        );
      },
    );
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
    final username = prefs.getString('username') ?? '';
    final encodedKey = prefs.getString('key');

    if (username.isEmpty || encodedKey == null) return;

    final key = base64Decode(encodedKey);
    final txList =
        _userTransactions
            .map(
              (tx) => jsonEncode({
                'id': tx.id,
                'title': tx.title,
                'category': tx.category,
                'amount': tx.amount,
                'isIncome': tx.isIncome,
                'date': tx.date.toIso8601String(),
              }),
            )
            .toList();

    final encryptedData = base64Encode(
      xorEncrypt(utf8.encode(jsonEncode(txList)), key),
    );

    await prefs.setString('tx_$username', encryptedData);
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? '';
    final encodedKey = prefs.getString('key');

    if (username.isEmpty || encodedKey == null) return;

    final key = base64Decode(encodedKey);
    final encryptedData = prefs.getString('tx_$username');

    if (encryptedData == null) return;

    try {
      final decryptedBytes =xorEncrypt(base64Decode(encryptedData), key);
      final List<dynamic> stringList = jsonDecode(utf8.decode(decryptedBytes));

      setState(() {
        _userTransactions =
            stringList.map((txString) {
              final Map<String, dynamic> map = jsonDecode(txString);
              return Transaction(
                id: map['id'],
                title: map['title'],
                category: map['category'],
                amount: map['amount'].toDouble(),
                isIncome: map['isIncome'],
                date: DateTime.parse(map['date']),
              );
            }).toList();
      });
    } catch (e) {
      print('❌ Error al descifrar: $e');
    }
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
            margin: const EdgeInsets.symmetric(horizontal: 20),
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
            child:
                filteredTransactions.isEmpty
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Vaya, esto está algo vacío;\nagreguemos algunos datos...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FloatingActionButton(
                          onPressed: () => _openTransactionForm(),
                          backgroundColor: Color(0xFF007AFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                    : TransactionList(
                      transactions: filteredTransactions,
                      onDelete: _confirmDelete,
                      onEdit: _openTransactionForm,
                    ),
          ),
        ],
      ),
      floatingActionButton:
          _userTransactions.isEmpty
              ? null
              : Padding(
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

          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        DashboardScreen(transactions: _userTransactions),
              ),
            );
          }
          if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) => ProfileScreen(transactions: _userTransactions),
              ),
            );
          }
        },
      ),
    );
  }
}
