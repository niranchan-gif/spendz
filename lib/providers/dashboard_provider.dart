import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardProvider with ChangeNotifier {
  double _totalBalance = 0;
  double _monthlyIncome = 0;
  double _monthlyExpenses = 0;
  double _monthlyTransfers = 0;
  double _monthlyRefunds = 0;
  double _totalOwed = 0;

  double _previousMonthIncome = 0;
  double _previousMonthExpenses = 0;

  double get totalBalance => _totalBalance;
  double get monthlyIncome => _monthlyIncome;
  double get monthlyExpenses => _monthlyExpenses;
  double get monthlyTransfers => _monthlyTransfers;
  double get monthlyRefunds => _monthlyRefunds;
  double get totalOwed => _totalOwed;

  double get incomeChange => _previousMonthIncome == 0
      ? 100
      : ((_monthlyIncome - _previousMonthIncome) / _previousMonthIncome) * 100;

  double get expenseChange => _previousMonthExpenses == 0
      ? 100
      : ((_monthlyExpenses - _previousMonthExpenses) / _previousMonthExpenses) *
            100;

  Map<String, double> _categorySpending = {};
  Map<String, double> get categorySpending => _categorySpending;

  void update(List<TransactionModel> transactions) {
    _calculateStats(transactions);
    notifyListeners();
  }

  void _calculateStats(List<TransactionModel> transactions) {
    _totalBalance = 0;
    _monthlyIncome = 0;
    _monthlyExpenses = 0;
    _monthlyTransfers = 0;
    _monthlyRefunds = 0;
    _totalOwed = 0;
    _previousMonthIncome = 0;
    _previousMonthExpenses = 0;
    _categorySpending = {};

    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    // Calculate previous month and year
    int prevMonth = currentMonth - 1;
    int prevYear = currentYear;
    if (prevMonth == 0) {
      prevMonth = 12;
      prevYear--;
    }

    for (var tx in transactions) {
      if (tx.type == 'income') {
        _totalBalance += tx.amount;
        if (tx.date.year == currentYear && tx.date.month == currentMonth) {
          _monthlyIncome += tx.amount;
        } else if (tx.date.year == prevYear && tx.date.month == prevMonth) {
          _previousMonthIncome += tx.amount;
        }
      } else if (tx.type == 'expense') {
        _totalBalance -= tx.amount;
        _totalOwed += tx.owedAmount;
        if (tx.date.year == currentYear && tx.date.month == currentMonth) {
          _monthlyExpenses += tx.amount;

          if (tx.categoryId != null) {
            _categorySpending[tx.categoryId!] =
                (_categorySpending[tx.categoryId!] ?? 0) + tx.amount;
          }
        } else if (tx.date.year == prevYear && tx.date.month == prevMonth) {
          _previousMonthExpenses += tx.amount;
        }
      } else if (tx.type == 'transfer') {
        _totalBalance += tx.amount;
        if (tx.date.year == currentYear && tx.date.month == currentMonth) {
          _monthlyTransfers += tx.amount;
        }
      } else if (tx.type == 'refund') {
        // DO NOT add to _totalBalance because it's already accounted for by reducing the expense.amount
        if (tx.date.year == currentYear && tx.date.month == currentMonth) {
          _monthlyRefunds += tx.amount;
        }
      }
    }
  }

  // Generate chart data for the current month
  List<FlSpot> getSpendingChartData(List<TransactionModel> transactions) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    // Group expenses by day
    Map<int, double> dailyExpenses = {};
    for (int i = 1; i <= 31; i++) {
      dailyExpenses[i] = 0; // Initialize all days
    }

    for (var tx in transactions) {
      if (tx.type == 'expense' &&
          tx.date.year == currentYear &&
          tx.date.month == currentMonth) {
        dailyExpenses[tx.date.day] =
            (dailyExpenses[tx.date.day] ?? 0) + tx.amount;
      }
    }

    List<FlSpot> spots = [];

    final daysInMonth = DateTime(currentYear, currentMonth + 1, 0).day;
    final currentDay = now.day;

    for (int i = 1; i <= daysInMonth; i++) {
      if (i > currentDay) break;
      spots.add(FlSpot(i.toDouble(), dailyExpenses[i] ?? 0));
    }

    return spots;
  }
}
