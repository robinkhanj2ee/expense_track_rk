# 💰 Finance Tracker — Flutter App

A beautiful, full-featured personal finance tracker with a built-in SQLite database. No internet connection required — all data is stored locally on the device.

---

## ✨ Features

| Feature | Details |
|---|---|
| 📊 Dashboard | Balance summary, income vs expense, recent transactions |
| ➕ Add Transactions | Income & expense with categories, date, and notes |
| ✏️ Edit / Delete | Swipe to edit or delete any transaction |
| 🔍 Search & Filter | Filter by income/expense, search by name or category |
| 📈 Analytics | Pie chart breakdown, category bars, savings rate |
| 🎯 Budget Tracking | Set monthly budgets per category, track progress |
| 🗃️ SQLite DB | All data stored locally via `sqflite` |
| 🌑 Dark Theme | Deep navy dark theme with purple accents |

---

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point & theme
├── models/
│   └── transaction_model.dart   # TransactionModel & BudgetModel
├── db/
│   └── database_helper.dart     # SQLite singleton + all CRUD operations
├── utils/
│   └── constants.dart           # Colors, categories, emoji icons
└── screens/
    ├── home_screen.dart          # Dashboard with balance card
    ├── add_transaction_screen.dart # Add/Edit transaction form
    ├── transactions_screen.dart  # Full transaction list with search
    ├── analytics_screen.dart     # Pie chart + category bars
    └── budget_screen.dart        # Monthly budget management
```

---

## 🚀 Setup & Run

### Prerequisites
- Flutter SDK ≥ 3.0.0
- Android Studio / Xcode
- A physical device or emulator

### Steps

```bash
# 1. Clone or copy this project
cd finance_tracker

# 2. Install dependencies
flutter pub get

# 3. Run on device/emulator
flutter run

# 4. Build release APK (Android)
flutter build apk --release

# 5. Build for iOS
flutter build ios --release
```

---

## 📦 Dependencies

| Package | Purpose |
|---|---|
| `sqflite` | SQLite database for local storage |
| `path` | File path utilities for DB location |
| `intl` | Date/number formatting |
| `fl_chart` | Pie chart and bar charts |
| `google_fonts` | Space Grotesk typeface |
| `flutter_slidable` | Swipe-to-edit/delete on transaction tiles |
| `uuid` | Generate unique IDs for records |
| `shared_preferences` | Lightweight key-value store for settings |

---

## 🗄️ Database Schema

### `transactions` table
| Column | Type | Description |
|---|---|---|
| id | TEXT PK | UUID |
| title | TEXT | Transaction name |
| amount | REAL | Amount in dollars |
| category | TEXT | Category label |
| type | TEXT | `'income'` or `'expense'` |
| date | TEXT | ISO 8601 date string |
| note | TEXT | Optional note |

### `budgets` table
| Column | Type | Description |
|---|---|---|
| id | TEXT PK | UUID |
| category | TEXT | Category label |
| limit | REAL | Monthly spending limit |
| month | TEXT | Format: `yyyy-MM` |

---

## 🎨 Design System

- **Background**: `#0F0F14` (near-black)
- **Surface**: `#1A1A24`
- **Card**: `#22222F`
- **Accent**: `#6C63FF` (purple)
- **Income**: `#2DD4A0` (teal)
- **Expense**: `#FF6584` (coral)
- **Font**: Space Grotesk (Google Fonts)

---

## 📱 Screens Overview

### 1. Home (Dashboard)
- Current month's balance card with gradient
- Income vs expense summary
- Quick action buttons
- 5 most recent transactions

### 2. Transactions
- Full list grouped by date (Today / Yesterday / date)
- Search bar + filter chips (All / Income / Expense)
- Swipe left → Edit or Delete

### 3. Analytics
- Income, Expense, Savings summary cards
- Interactive pie chart (tap slice to see %)
- Top spending categories with progress bars
- Savings rate percentage

### 4. Budget
- Set monthly spending limits per category
- Progress bar (green → orange → red as you approach limit)
- Swipe to delete budget
- Over-budget alert shown inline
