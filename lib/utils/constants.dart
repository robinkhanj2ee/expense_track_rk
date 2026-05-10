// lib/utils/constants.dart

import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0F0F14);
  static const surface = Color(0xFF1A1A24);
  static const card = Color(0xFF22222F);
  static const accent = Color(0xFF6C63FF);
  static const accentLight = Color(0xFF9D97FF);
  static const income = Color(0xFF2DD4A0);
  static const expense = Color(0xFFFF6584);
  static const textPrimary = Color(0xFFF0F0FF);
  static const textSecondary = Color(0xFF8888AA);
  static const border = Color(0xFF2E2E40);

  static const categoryColors = [
    Color(0xFF6C63FF),
    Color(0xFF2DD4A0),
    Color(0xFFFF6584),
    Color(0xFFFFB347),
    Color(0xFF56CCF2),
    Color(0xFFBB6BD9),
    Color(0xFFEB5757),
    Color(0xFF27AE60),
  ];
}

class AppCategories {
  static const expenseCategories = [
    'Food & Drinks',
    'Transport',
    'Shopping',
    'Entertainment',
    'Health',
    'Housing',
    'Education',
    'Travel',
    'Bills',
    'Other',
  ];

  static const incomeCategories = [
    'Salary',
    'Freelance',
    'Investment',
    'Gift',
    'Business',
    'Other',
  ];

  static const categoryIcons = {
    'Food & Drinks': '🍔',
    'Transport': '🚗',
    'Shopping': '🛍️',
    'Entertainment': '🎬',
    'Health': '💊',
    'Housing': '🏠',
    'Education': '📚',
    'Travel': '✈️',
    'Bills': '📄',
    'Salary': '💼',
    'Freelance': '💻',
    'Investment': '📈',
    'Gift': '🎁',
    'Business': '🏢',
    'Other': '📦',
  };
}
