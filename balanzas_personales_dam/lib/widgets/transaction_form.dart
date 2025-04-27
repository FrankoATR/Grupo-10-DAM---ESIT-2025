import 'package:flutter/material.dart';
import '../models/transaction.dart';

class TransactionForm extends StatefulWidget {
  final Function(Transaction) onSubmit;
  final Transaction? existingTransaction;

  TransactionForm({required this.onSubmit, this.existingTransaction});

  @override
  _TransactionFormState createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isIncome = true;

  @override
  void initState() {
    super.initState();
    if (widget.existingTransaction != null) {
      _titleController.text = widget.existingTransaction!.title;
      _amountController.text = widget.existingTransaction!.amount.toString();
      _isIncome = widget.existingTransaction!.isIncome;
    }
  }

  void _submitData() {
    final enteredTitle = _titleController.text;
    final enteredAmount = double.tryParse(_amountController.text) ?? 0;

    if (enteredTitle.isEmpty || enteredAmount <= 0) {
      return;
    }

    final newTransaction = Transaction(
      id: widget.existingTransaction?.id ?? DateTime.now().toString(),
      title: enteredTitle,
      amount: enteredAmount,
      isIncome: _isIncome,
      date: DateTime.now(),
    );

    widget.onSubmit(newTransaction);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(labelText: 'Descripción'),
          ),
          TextField(
            controller: _amountController,
            decoration: InputDecoration(labelText: 'Cantidad'),
            keyboardType: TextInputType.number,
          ),
          SwitchListTile(
            title: Text(_isIncome ? 'Entrada (+)' : 'Salida (-)'),
            value: _isIncome,
            onChanged: (val) {
              setState(() {
                _isIncome = val;
              });
            },
          ),
          ElevatedButton(onPressed: _submitData, child: Text('Guardar')),
        ],
      ),
    );
  }
}
