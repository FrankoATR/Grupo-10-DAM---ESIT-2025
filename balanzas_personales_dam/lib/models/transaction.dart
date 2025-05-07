class Transaction {
  String id;
  String title;
  String category;
  double amount;
  bool isIncome;
  DateTime date;

  Transaction({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.isIncome,
    required this.date,
  });
}
