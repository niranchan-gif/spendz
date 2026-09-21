import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/imported_transaction.dart';
import '../models/transaction_model.dart';
import '../services/hdfc_gmail_service.dart';
import '../database/transaction_dao.dart';
import '../providers/transaction_provider.dart';

class GmailImportProvider with ChangeNotifier {
  final HdfcGmailService _apiService = HdfcGmailService();
  final TransactionDao _transactionDao = TransactionDao();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<ImportedTransaction> _newTransactions = [];
  List<ImportedTransaction> get newTransactions => _newTransactions;

  Future<void> reloadTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fetchedTransactions = await _apiService.fetchTransactions();
      
      final List<ImportedTransaction> filteredList = [];
      
      for (final tx in fetchedTransactions) {
        if (tx.reference.isEmpty) {
          continue; // skip transactions without a reference
        }
        final exists = await _transactionDao.transactionExistsWithReference(tx.reference);
        if (!exists) {
          // Double check it's not already added in the current session
          if (!filteredList.any((t) => t.reference == tx.reference)) {
            filteredList.add(tx);
          }
        }
      }
      
      _newTransactions = filteredList;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void removeTransaction(ImportedTransaction tx) {
    _newTransactions.remove(tx);
    notifyListeners();
  }

  Future<int> autoSync(TransactionProvider txProvider) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    int addedCount = 0;

    try {
      final fetchedTransactions = await _apiService.fetchTransactions();
      
      for (final tx in fetchedTransactions) {
        if (tx.reference.isEmpty) continue;
        
        final exists = await _transactionDao.transactionExistsWithReference(tx.reference);
        if (!exists) {
          final isExpense = tx.type.toUpperCase() == 'DEBIT';
          final transaction = TransactionModel(
            id: const Uuid().v4(),
            amount: tx.amount,
            type: isExpense ? 'expense' : 'income',
            merchant: tx.name,
            description: 'Imported from Gmail',
            date: tx.date,
            source: 'bank_email',
            bankName: tx.source,
            referenceId: tx.reference,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await txProvider.addTransaction(transaction);
          addedCount++;
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    
    return addedCount;
  }
}
