// lib/screens/transactions_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/transaction_model.dart';
import '../utils/constants.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  final VoidCallback? onRefresh;
  const TransactionsScreen({super.key, this.onRefresh});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _db = DatabaseHelper();
  List<TransactionModel> _all = [];
  List<TransactionModel> _filtered = [];
  String _filter = 'all'; // all, income, expense
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final txns = await _db.getAllTransactions();
    setState(() {
      _all = txns;
      _applyFilter();
    });
  }

  void _applyFilter() {
    var list = _all;
    if (_filter != 'all') list = list.where((t) => t.type == _filter).toList();
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((t) =>
              t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              t.category.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    _filtered = list;
  }

  Future<void> _delete(TransactionModel tx) async {
    await _db.deleteTransaction(tx.id);
    widget.onRefresh?.call();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    // Group by date
    final Map<String, List<TransactionModel>> grouped = {};
    for (final tx in _filtered) {
      final key = DateFormat('yyyy-MM-dd').format(tx.date);
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Transactions',
                    style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                // Search bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textPrimary, fontSize: 14),
                    onChanged: (v) =>
                        setState(() {
                          _searchQuery = v;
                          _applyFilter();
                        }),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search transactions...',
                      hintStyle: GoogleFonts.spaceGrotesk(
                          color: AppColors.textSecondary, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppColors.textSecondary, size: 20),
                      prefixIconConstraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter chips
                Row(
                  children: [
                    _chip('All', 'all'),
                    const SizedBox(width: 8),
                    _chip('Income', 'income'),
                    const SizedBox(width: 8),
                    _chip('Expense', 'expense'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('📭', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text('No transactions found',
                            style: GoogleFonts.spaceGrotesk(
                                color: AppColors.textSecondary, fontSize: 16)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppColors.accent,
                    backgroundColor: AppColors.surface,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: sortedKeys.length,
                      itemBuilder: (ctx, i) {
                        final dateKey = sortedKeys[i];
                        final dayTxns = grouped[dateKey]!;
                        final date = DateTime.parse(dateKey);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                _formatDate(date),
                                style: GoogleFonts.spaceGrotesk(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            ...dayTxns.map((tx) => _SlidableTile(
                                tx: tx,
                                onDelete: () => _delete(tx),
                                onEdit: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => AddTransactionScreen(
                                            existing: tx)),
                                  );
                                  _load();
                                })),
                          ],
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() {
        _filter = value;
        _applyFilter();
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.accent : AppColors.border),
        ),
        child: Text(label,
            style: GoogleFonts.spaceGrotesk(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('EEEE, MMM d').format(date);
  }
}

class _SlidableTile extends StatelessWidget {
  final TransactionModel tx;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _SlidableTile({
    required this.tx,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final emoji = AppCategories.categoryIcons[tx.category] ?? '📦';
    final isExpense = tx.isExpense;
    final color = isExpense ? AppColors.expense : AppColors.income;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.4,
          children: [
            SlidableAction(
              onPressed: (_) => onEdit(),
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              icon: Icons.edit_rounded,
              label: 'Edit',
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            SlidableAction(
              onPressed: (_) => onDelete(),
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
              icon: Icons.delete_rounded,
              label: 'Delete',
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                    child:
                        Text(emoji, style: const TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.title,
                        style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    Text(tx.category,
                        style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textSecondary, fontSize: 12)),
                    if (tx.note != null && tx.note!.isNotEmpty)
                      Text(tx.note!,
                          style: GoogleFonts.spaceGrotesk(
                              color: AppColors.textSecondary.withOpacity(0.7),
                              fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Text('${isExpense ? '-' : '+'}\$${fmt.format(tx.amount)}',
                  style: GoogleFonts.spaceGrotesk(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
