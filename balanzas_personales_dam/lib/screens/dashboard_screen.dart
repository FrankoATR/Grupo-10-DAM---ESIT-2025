import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  final List<Transaction> transactions;

  DashboardScreen({required this.transactions});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _filterType = 'Todo';
  String _sortOrder = 'Reciente';
  int _currentIndex = 1;

  List<Transaction> get _filteredTransactions {
    final now = DateTime.now();
    return widget.transactions.where((tx) {
        final sameMonth =
            tx.date.month == now.month && tx.date.year == now.year;
        if (!sameMonth) return false;

        if (_filterType == 'Entrada') return tx.isIncome;
        if (_filterType == 'Salida') return !tx.isIncome;
        return true;
      }).toList()
      ..sort(
        (a, b) =>
            _sortOrder == 'Reciente'
                ? b.date.compareTo(a.date)
                : a.date.compareTo(b.date),
      );
  }

  List<MapEntry<DateTime, double>> get _groupedDailyTotals {
    final Map<DateTime, double> dailyTotals = {};

    for (var tx in _filteredTransactions) {
      final day = DateTime(tx.date.year, tx.date.month, tx.date.day);
      final amount = tx.isIncome ? tx.amount : -tx.amount;
      dailyTotals.update(day, (prev) => prev + amount, ifAbsent: () => amount);
    }

    final sortedEntries =
        dailyTotals.entries.toList()..sort(
          (a, b) =>
              _sortOrder == 'Reciente'
                  ? b.key.compareTo(a.key)
                  : a.key.compareTo(b.key),
        );

    return sortedEntries;
  }

  double get _netTotal => _filteredTransactions.fold(
    0,
    (sum, tx) => tx.isIncome ? sum + tx.amount : sum - tx.amount,
  );
  double get _maxIncome => _filteredTransactions
      .where((tx) => tx.isIncome)
      .fold(0, (max, tx) => tx.amount > max ? tx.amount : max);
  double get _maxLoss => _filteredTransactions
      .where((tx) => !tx.isIncome)
      .fold(0, (max, tx) => tx.amount > max ? tx.amount : max);

  @override
  Widget build(BuildContext context) {
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
              'Dashboard',
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
                  children: [
                    const Text(
                      'Mostrar:',
                      style: TextStyle(
                        color: Color(0xFF2C14DD),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Wrap(
                        spacing: 10,
                        children: [
                          FilterChip(
                            label: const Text('Entrada'),
                            selected: _filterType == 'Entrada',
                            onSelected:
                                (_) => setState(() => _filterType = 'Entrada'),
                          ),
                          FilterChip(
                            label: const Text('Salida'),
                            selected: _filterType == 'Salida',
                            onSelected:
                                (_) => setState(() => _filterType = 'Salida'),
                          ),
                          FilterChip(
                            label: const Text('Todo'),
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
                  children: [
                    const Text(
                      'Ordenar por:',
                      style: TextStyle(
                        color: Color(0xFF2C14DD),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Wrap(
                        spacing: 10,
                        children: [
                          ChoiceChip(
                            label: const Text('Reciente'),
                            selected: _sortOrder == 'Reciente',
                            onSelected:
                                (_) => setState(() => _sortOrder = 'Reciente'),
                          ),
                          ChoiceChip(
                            label: const Text('Antiguo'),
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

          const Text(
            'Estadísticas de este mes',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 40,
              height: 200,
              child: LineChart(
                LineChartData(
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index < 0 ||
                              index >= _groupedDailyTotals.length) {
                            return const SizedBox.shrink();
                          }

                          final date = _groupedDailyTotals[index].key;
                          final formatted = DateFormat(
                            'd MMM',
                            'es',
                          ).format(date);

                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 6,
                            child: Text(
                              formatted,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 25,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value >= 0
                                ? '\$${value.toStringAsFixed(0)}'
                                : '-\$${value.abs().toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),

                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots:
                          _groupedDailyTotals
                              .asMap()
                              .entries
                              .map(
                                (e) => FlSpot(
                                  e.key.toDouble(),
                                  e.value.value,
                                ),
                              )
                              .toList(),
                      isCurved: true,
                      color: Colors.black,
                      barWidth: 2,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          final isPositive = spot.y >= 0;
                          return FlDotCirclePainter(
                            radius: 4,
                            color:
                                isPositive
                                    ? Color(0xFF2C14DD)
                                    : Color(0xFFFF2D55),
                            strokeWidth: 1,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _StatCard(
                  label: "Beneficio",
                  value: _netTotal,
                  color: Color(0xFF2C14DD),
                ),
                _StatCard(
                  label: "Mayor ingreso",
                  value: _maxIncome,
                  color: Color(0xFF2C14DD),
                ),
                _StatCard(
                  label: "Mayor perdida",
                  value: _maxLoss,
                  color: Color(0xFFFF2D55),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          }
          if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen(transactions: widget.transactions)),
            );
          }
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
