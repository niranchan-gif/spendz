import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/imported_transaction.dart';
import '../models/transaction_model.dart';
import '../services/hdfc_gmail_service.dart';
import '../services/category_engine.dart';
import '../database/transaction_dao.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';

class GmailImportProvider with ChangeNotifier {
  final HdfcGmailService _apiService = HdfcGmailService();
  final TransactionDao _transactionDao = TransactionDao();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<ImportedTransaction> _newTransactions = [];
  List<ImportedTransaction> get newTransactions => _newTransactions;
  
  DateTime? _syncRangeStart;
  DateTime? _syncRangeEnd;
  
  DateTime? get syncRangeStart => _syncRangeStart;
  DateTime? get syncRangeEnd => _syncRangeEnd;

  Future<void> reloadTransactions(CategoryProvider categoryProvider) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString('last_hdfc_sync_date');
      
      final today = DateTime.now();
      
      if (lastSyncStr == null) {
        _syncRangeStart = today;
        _syncRangeEnd = today;
      } else {
        _syncRangeStart = DateTime.tryParse(lastSyncStr) ?? today;
        _syncRangeEnd = today;
      }

      final fetchedTransactions = await _apiService.fetchTransactions(
        startDate: _syncRangeStart!,
        endDate: _syncRangeEnd!,
      );
      
      final List<ImportedTransaction> filteredList = [];
      
      for (var tx in fetchedTransactions) {
        if (tx.reference.isEmpty) {
          continue; // skip transactions without a reference
        }
        final exists = await _transactionDao.transactionExistsWithReference(tx.reference, amount: tx.amount, date: tx.date);
        if (!exists) {
          // Double check it's not already added in the current session
          if (!filteredList.any((t) => t.reference == tx.reference)) {
            final isParent = CategoryEngine.isParentTransfer(tx.name);
            
            if (isParent) {
              tx = tx.copyWith(type: 'transfer', suggestedCategoryId: null);
              debugPrint('TX ${tx.name} identified as PARENT TRANSFER');
            } else {
              final suggestedCategory = CategoryEngine.suggestCategoryId(tx.name, tx.type, categoryProvider);
              debugPrint('TX ${tx.name} -> CategoryEngine suggested: $suggestedCategory');
              tx = tx.copyWith(suggestedCategoryId: suggestedCategory);
            }
            
            filteredList.add(tx);
          }
        }
      }
      
      _newTransactions = filteredList;
      
      // ONLY update the sync date after successful fetching and processing
      final formatter = DateFormat('yyyy-MM-dd');
      await prefs.setString('last_hdfc_sync_date', formatter.format(today));
      
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

  void updateCategory(String reference, String newCategoryId) {
    final index = _newTransactions.indexWhere((t) => t.reference == reference);
    if (index != -1) {
      _newTransactions[index] = _newTransactions[index].copyWith(suggestedCategoryId: newCategoryId);
      notifyListeners();
    }
  }

  Future<void> approveTransaction(String reference, TransactionProvider txProvider) async {
    final index = _newTransactions.indexWhere((t) => t.reference == reference);
    if (index == -1) return;

    final tx = _newTransactions[index];
    
    // Final duplicate check
    final exists = await _transactionDao.transactionExistsWithReference(tx.reference, amount: tx.amount, date: tx.date);
    if (exists) {
      _newTransactions.removeAt(index);
      notifyListeners();
      return;
    }

    final isParent = CategoryEngine.isParentTransfer(tx.name);
    final isExpense = tx.type.toUpperCase() == 'DEBIT';
    
    final String finalType = isParent ? 'transfer' : (isExpense ? 'expense' : 'income');

    final transaction = TransactionModel(
      id: const Uuid().v4(),
      amount: tx.amount,
      type: finalType,
      categoryId: tx.suggestedCategoryId,
      merchant: tx.name,
      description: 'Imported from HDFC Gmail',
      date: tx.date,
      paymentMethod: 'UPI',
      source: 'bank_email',
      bankName: 'HDFC',
      referenceId: tx.reference,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await txProvider.addTransaction(transaction);
      _newTransactions.removeAt(index);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to insert transaction into database: $e');
    }
  }

  Future<int> approveAll(TransactionProvider txProvider) async {
    _isLoading = true;
    notifyListeners();

    int addedCount = 0;
    
    try {
      // Create a copy to iterate safely
      final pendingList = List<ImportedTransaction>.from(_newTransactions);
      
      for (final tx in pendingList) {
        final exists = await _transactionDao.transactionExistsWithReference(tx.reference, amount: tx.amount, date: tx.date);
        if (!exists) {
          final isParent = CategoryEngine.isParentTransfer(tx.name);
          final isExpense = tx.type.toUpperCase() == 'DEBIT';
          
          final String finalType = isParent ? 'transfer' : (isExpense ? 'expense' : 'income');
          
          final transaction = TransactionModel(
            id: const Uuid().v4(),
            amount: tx.amount,
            type: finalType,
            categoryId: tx.suggestedCategoryId,
            merchant: tx.name,
            description: 'Imported from HDFC Gmail',
            date: tx.date,
            paymentMethod: 'UPI',
            source: 'bank_email',
            bankName: 'HDFC',
            referenceId: tx.reference,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          try {
            await txProvider.addTransaction(transaction);
            // Only remove from the primary list if insertion succeeded
            _newTransactions.removeWhere((t) => t.reference == tx.reference);
            addedCount++;
          } catch (e) {
            // Keep it in _newTransactions, log or ignore the specific failure so the rest can process
            debugPrint('Failed to insert transaction ${tx.reference}: $e');
          }
        } else {
          // It exists in the DB, safe to clear from pending
          _newTransactions.removeWhere((t) => t.reference == tx.reference);
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    
    return addedCount;
  }
}
