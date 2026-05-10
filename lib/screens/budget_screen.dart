// lib/screens/budget_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../db/database_helper.dart';
import '../models/transaction_model.dart';
import '../utils/constants.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _db = DatabaseHelper();
  List<BudgetModel> _budgets = [];
  Map<String, double> _spent = {};
  final _currentMonth = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final budgets = await _db.getBudgetsByMonth(_currentMonth);
    final spent = await _db.getCategoryTotals(_currentMonth, 'expense');
    setState(() {
      _budgets = budgets;
      _spent = spent;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Budgets',
                        style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w700)),
                    Text(DateFormat('MMMM yyyy').format(DateTime.now()),
                        style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textSecondary, fontSize: 14)),
                  ],
                ),
                GestureDetector(
                  onTap: _showAddBudget,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.add, color: AppColors.accent, size: 16),
                        const SizedBox(width: 4),
                        Text('Add Budget',
                            style: GoogleFonts.spaceGrotesk(
                                color: AppColors.accent,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _budgets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🎯', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text('No budgets set',
                            style: GoogleFonts.spaceGrotesk(
                                color: AppColors.textSecondary, fontSize: 16)),
                        const SizedBox(height: 6),
                        Text('Tap "Add Budget" to get started',
                            style: GoogleFonts.spaceGrotesk(
                                color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppColors.accent,
                    backgroundColor: AppColors.surface,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _budgets.length,
                      itemBuilder: (ctx, i) {
                        final b = _budgets[i];
                        final spent = _spent[b.category] ?? 0.0;
                        final pct = (spent / b.limit).clamp(0.0, 1.0);
                        final remaining = b.limit - spent;
                        final isOver = spent > b.limit;
                        final color = isOver
                            ? AppColors.expense
                            : pct > 0.8
                                ? const Color(0xFFFFB347)
                                : AppColors.income;
                        final emoji =
                            AppCategories.categoryIcons[b.category] ?? '📦';
                        final fmt = NumberFormat('#,##0.00');

                        return Dismissible(
                          key: Key(b.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.expense.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.delete_rounded,
                                color: AppColors.expense),
                          ),
                          onDismissed: (_) async {
                            await _db.deleteBudget(b.id);
                            _load();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppColors.border, width: 0.5),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Text(emoji,
                                        style:
                                            const TextStyle(fontSize: 22)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(b.category,
                                          style: GoogleFonts.spaceGrotesk(
                                              color: AppColors.textPrimary,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                            '\$${fmt.format(spent)} / \$${fmt.format(b.limit)}',
                                            style: GoogleFonts.spaceGrotesk(
                                                color: AppColors.textPrimary,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600)),
                                        Text(
                                            isOver
                                                ? 'Over by \$${fmt.format(spent - b.limit)}'
                                                : '\$${fmt.format(remaining)} left',
                                            style: GoogleFonts.spaceGrotesk(
                                                color: color, fontSize: 11)),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    backgroundColor: AppColors.surface,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(color),
                                    minHeight: 8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddBudget() {
    final categories = AppCategories.expenseCategories;
    String selectedCategory = categories.first;
    final amountCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20),
        child: StatefulBuilder(
          builder: (ctx2, setLS) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Set Budget',
                  style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              Text('Category',
                  style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButton<String>(
                  value: selectedCategory,
                  isExpanded: true,
                  dropdownColor: AppColors.card,
                  underline: const SizedBox(),
                  style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textPrimary, fontSize: 14),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setLS(() => selectedCategory = v!),
                ),
              ),
              const SizedBox(height: 16),
              Text('Monthly Limit',
                  style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0.00',
                    prefixText: '\$ ',
                    prefixStyle: GoogleFonts.spaceGrotesk(
                        color: AppColors.accent, fontSize: 15),
                    hintStyle: GoogleFonts.spaceGrotesk(
                        color: AppColors.textSecondary, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final limit = double.tryParse(amountCtrl.text);
                    if (limit == null || limit <= 0) return;
                    await _db.upsertBudget(BudgetModel(
                      id: const Uuid().v4(),
                      category: selectedCategory,
                      limit: limit,
                      month: _currentMonth,
                    ));
                    Navigator.pop(ctx);
                    _load();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text('Save Budget',
                      style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
