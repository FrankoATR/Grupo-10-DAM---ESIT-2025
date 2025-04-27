class Transaction {
  String id;
  String title;
  double amount;
  bool isIncome; // true = entrada, false = salida
  DateTime date;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.date,
  });
}
