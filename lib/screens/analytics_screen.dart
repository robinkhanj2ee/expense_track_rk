// lib/screens/analytics_screen.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../utils/constants.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _db = DatabaseHelper();
  Map<String, double> _expenseByCategory = {};
  Map<String, double> _incomeByCategory = {};
  double _totalIncome = 0;
  double _totalExpense = 0;
  int _touchedIndex = -1;
  final _currentMonth = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final expCat = await _db.getCategoryTotals(_currentMonth, 'expense');
    final incCat = await _db.getCategoryTotals(_currentMonth, 'income');
    final income = await _db.getTotalByType(_currentMonth, 'income');
    final expense = await _db.getTotalByType(_currentMonth, 'expense');
    setState(() {
      _expenseByCategory = expCat;
      _incomeByCategory = incCat;
      _totalIncome = income;
      _totalExpense = expense;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final savings = _totalIncome - _totalExpense;
    final savingsRate = _totalIncome > 0
        ? (savings / _totalIncome * 100).clamp(0, 100)
        : 0.0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Analytics',
                style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700)),
            Text(DateFormat('MMMM yyyy').format(DateTime.now()),
                style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 24),

            // Summary cards
            Row(
              children: [
                _summaryCard('Income', _totalIncome, AppColors.income),
                const SizedBox(width: 12),
                _summaryCard('Expenses', _totalExpense, AppColors.expense),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Savings',
                        style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textSecondary, fontSize: 13)),
                    Text('\$${fmt.format(savings)}',
                        style: GoogleFonts.spaceGrotesk(
                            color: savings >= 0
                                ? AppColors.income
                                : AppColors.expense,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                  ]),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('Savings Rate',
                        style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textSecondary, fontSize: 13)),
                    Text('${savingsRate.toStringAsFixed(1)}%',
                        style: GoogleFonts.spaceGrotesk(
                            color: AppColors.accent,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Expense Pie Chart
            if (_expenseByCategory.isNotEmpty) ...[
              Text('Expense Breakdown',
                  style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 220,
                      child: PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (_, pieTouchResponse) {
                              setState(() {
                                if (pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  _touchedIndex = -1;
                                  return;
                                }
                                _touchedIndex = pieTouchResponse
                                    .touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          sections: _buildPieSections(_expenseByCategory),
                          centerSpaceRadius: 50,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: _expenseByCategory.entries
                          .toList()
                          .asMap()
                          .entries
                          .map((e) => _legend(
                              e.value.key,
                              e.value.value,
                              AppColors.categoryColors[
                                  e.key % AppColors.categoryColors.length]))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Category bars
            if (_expenseByCategory.isNotEmpty) ...[
              Text('Top Spending Categories',
                  style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ..._expenseByCategory.entries
                  .toList()
                  .take(5)
                  .map((e) => _categoryBar(e.key, e.value, _totalExpense)),
            ],
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(Map<String, double> data) {
    final entries = data.entries.toList();
    final total = data.values.fold(0.0, (a, b) => a + b);
    return entries.asMap().entries.map((e) {
      final isTouched = e.key == _touchedIndex;
      final color =
          AppColors.categoryColors[e.key % AppColors.categoryColors.length];
      final pct = total > 0 ? (e.value.value / total * 100) : 0;
      return PieChartSectionData(
        color: color,
        value: e.value.value,
        title: isTouched ? '${pct.toStringAsFixed(1)}%' : '',
        radius: isTouched ? 70 : 60,
        titleStyle: GoogleFonts.spaceGrotesk(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
      );
    }).toList();
  }

  Widget _legend(String label, double amount, Color color) {
    final fmt = NumberFormat('#,##0');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label (\$${fmt.format(amount)})',
            style: GoogleFonts.spaceGrotesk(
                color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _summaryCard(String label, double amount, Color color) {
    final fmt = NumberFormat('#,##0.00');
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.spaceGrotesk(
                    color: color, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('\$${fmt.format(amount)}',
                style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _categoryBar(String category, double amount, double total) {
    final pct = total > 0 ? amount / total : 0.0;
    final fmt = NumberFormat('#,##0.00');
    final emoji = AppCategories.categoryIcons[category] ?? '📦';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(category,
                    style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textPrimary, fontSize: 13)),
              ),
              Text('\$${fmt.format(amount)}',
                  style: GoogleFonts.spaceGrotesk(
                      color: AppColors.expense,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.surface,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.expense),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
