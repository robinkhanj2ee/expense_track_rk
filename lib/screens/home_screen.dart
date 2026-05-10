// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/transaction_model.dart';
import '../utils/constants.dart';
import 'add_transaction_screen.dart';
import 'transactions_screen.dart';
import 'analytics_screen.dart';
import 'budget_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _db = DatabaseHelper();
  double _totalIncome = 0;
  double _totalExpense = 0;
  List<TransactionModel> _recentTransactions = [];
  final _currentMonth = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final income = await _db.getTotalByType(_currentMonth, 'income');
    final expense = await _db.getTotalByType(_currentMonth, 'expense');
    final txns = await _db.getTransactionsByMonth(_currentMonth);
    setState(() {
      _totalIncome = income;
      _totalExpense = expense;
      _recentTransactions = txns.take(5).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DashboardPage(
        totalIncome: _totalIncome,
        totalExpense: _totalExpense,
        recentTransactions: _recentTransactions,
        onRefresh: _loadData,
        onAddTap: () => _showAddTransaction(),
      ),
      TransactionsScreen(onRefresh: _loadData),
      AnalyticsScreen(),
      BudgetScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: pages[_currentIndex],
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: _showAddTransaction,
              backgroundColor: AppColors.accent,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
              top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle:
              GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.spaceGrotesk(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_rounded), label: 'Transactions'),
            BottomNavigationBarItem(
                icon: Icon(Icons.pie_chart_rounded), label: 'Analytics'),
            BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Budget'),
          ],
        ),
      ),
    );
  }

  void _showAddTransaction() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
    _loadData();
  }
}

class _DashboardPage extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final List<TransactionModel> recentTransactions;
  final VoidCallback onRefresh;
  final VoidCallback onAddTap;

  const _DashboardPage({
    required this.totalIncome,
    required this.totalExpense,
    required this.recentTransactions,
    required this.onRefresh,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final balance = totalIncome - totalExpense;
    final fmt = NumberFormat('#,##0.00');
    final monthName = DateFormat('MMMM yyyy').format(DateTime.now());

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => onRefresh(),
        color: AppColors.accent,
        backgroundColor: AppColors.surface,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Good ${_greeting()}!',
                                style: GoogleFonts.spaceGrotesk(
                                    color: AppColors.textSecondary,
                                    fontSize: 14)),
                            Text('Finance Tracker',
                                style: GoogleFonts.spaceGrotesk(
                                    color: AppColors.textPrimary,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.notifications_rounded,
                              color: AppColors.accent, size: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Balance Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF9D97FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(monthName,
                              style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white60, fontSize: 13)),
                          const SizedBox(height: 8),
                          Text('Total Balance',
                              style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('\$${fmt.format(balance)}',
                              style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              _balanceStat(
                                  '↑ Income', '\$${fmt.format(totalIncome)}',
                                  AppColors.income),
                              const SizedBox(width: 24),
                              _balanceStat(
                                  '↓ Expense', '\$${fmt.format(totalExpense)}',
                                  AppColors.expense),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Quick Actions
                    Text('Quick Actions',
                        style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _quickAction(
                            Icons.add_circle_rounded, 'Add', AppColors.accent,
                            onAddTap),
                        const SizedBox(width: 12),
                        _quickAction(Icons.pie_chart_rounded, 'Analytics',
                            AppColors.income, () {}),
                        const SizedBox(width: 12),
                        _quickAction(Icons.account_balance_wallet_rounded,
                            'Budget', AppColors.expense, () {}),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Recent Transactions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Transactions',
                            style: GoogleFonts.spaceGrotesk(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        Text('See all',
                            style: GoogleFonts.spaceGrotesk(
                                color: AppColors.accent, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            recentTransactions.isEmpty
                ? SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            const Text('💸', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text('No transactions yet',
                                style: GoogleFonts.spaceGrotesk(
                                    color: AppColors.textSecondary,
                                    fontSize: 16)),
                            const SizedBox(height: 6),
                            Text('Tap + to add your first one',
                                style: GoogleFonts.spaceGrotesk(
                                    color: AppColors.textSecondary,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final tx = recentTransactions[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 4),
                          child: _TransactionTile(tx: tx),
                        );
                      },
                      childCount: recentTransactions.length,
                    ),
                  ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _balanceStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.spaceGrotesk(
                color: Colors.white60, fontSize: 12)),
        Text(value,
            style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _quickAction(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(label,
                  style: GoogleFonts.spaceGrotesk(
                      color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final emoji = AppCategories.categoryIcons[tx.category] ?? '📦';
    final isExpense = tx.isExpense;
    final color = isExpense ? AppColors.expense : AppColors.income;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
                child: Text(emoji, style: const TextStyle(fontSize: 20))),
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
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${isExpense ? '-' : '+'}\$${fmt.format(tx.amount)}',
                  style: GoogleFonts.spaceGrotesk(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              Text(DateFormat('MMM d').format(tx.date),
                  style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
