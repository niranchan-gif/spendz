import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../database/transaction_dao.dart';

class TransactionProvider with ChangeNotifier {
  final TransactionDao _transactionDao = TransactionDao();
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;

  TransactionProvider() {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();

    _transactions = await _transactionDao.getAllTransactions();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await _transactionDao.insert(transaction);
    await loadTransactions();
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _transactionDao.update(transaction);
    await loadTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    await _transactionDao.delete(id);
    await loadTransactions();
  }

  List<TransactionModel> getTransactionsForMonth(int year, int month) {
    return _transactions.where((t) => t.date.year == year && t.date.month == month).toList();
  }

  List<TransactionModel> getRecentTransactions({int count = 5}) {
    return _transactions.take(count).toList();
  }
}
