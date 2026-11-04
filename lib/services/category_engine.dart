import 'package:flutter/foundation.dart';
import '../providers/category_provider.dart';

class CategoryEngine {
  static String? suggestCategoryId(
    String merchant,
    String type,
    CategoryProvider provider,
  ) {
    if (merchant.isEmpty) return _getOtherCategoryId(type, provider);

    // 1. Parent Transfers skip category suggestion completely
    if (isParentTransfer(merchant)) return null;

    final normalized = merchant
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ');

    // 2. & 3. & 4. Find Category Name based on rules
    final suggestedName = _findCategoryName(normalized, type);

    if (suggestedName != null) {
      final matchedCategory = _findCategoryByName(
        suggestedName,
        type,
        provider,
      );
      if (matchedCategory != null) {
        return matchedCategory;
      } else {
        debugPrint(
          'CategoryEngine: Found rule for $suggestedName but _findCategoryByName returned null. Are categories loaded?',
        );
      }
    }

    // 5. Fallback
    final fallback = _getOtherCategoryId(type, provider);
    if (fallback == null) {
      debugPrint(
        'CategoryEngine: Fallback also returned null. Category list length: ${provider.categories.length}',
      );
    }
    return fallback;
  }

  /// Determines if a transaction is a parent transfer based on merchant name.
  static bool isParentTransfer(String merchant) {
    final normalized = merchant.toUpperCase().trim();
    return normalized.contains('VIJAYALAKSHMI MUTHUKUMAR') ||
        normalized.contains('MUTHUKUMAR');
  }

  static String? _findCategoryName(String normalized, String type) {
    if (type.toUpperCase() == 'CREDIT') {
      if (normalized.contains('salary') || normalized.contains('payroll'))
        return 'Salary';
      if (normalized.contains('refund') ||
          normalized.contains('cashback') ||
          normalized.contains('reversal'))
        return 'Refund';
      if (normalized.contains('interest')) return 'Interest';
      return 'Other Income';
    }

    // Exact or specific merchant rules (Highest priority)
    if (normalized.contains('blasis corner')) return 'Food & Dining';
    if (normalized.contains('kishan cafe')) return 'Food & Dining';
    if (normalized.contains('chandra food products')) return 'Food & Dining';

    if (normalized.contains('state transport corporation') ||
        normalized.contains('state transpo'))
      return 'Transport';
    if (normalized.contains('tamilnadu state transport') ||
        normalized.contains('tamilnadu state transpo'))
      return 'Transport';
    if (normalized.contains('metropolitan transport corporation') ||
        normalized.contains('metropolitan transpo'))
      return 'Transport';
    if (normalized.contains('indian railways')) return 'Transport';
    if (normalized.contains('irctc')) return 'Transport';
    if (normalized.contains('redbus') || normalized.contains('red bus'))
      return 'Transport';
    if (normalized.contains('abhibus')) return 'Transport';
    if (normalized.contains('cumta')) return 'Transport';

    if (normalized.contains('amazon pay balance') ||
        normalized.contains('amazon pay'))
      return 'Shopping';
    if (normalized.contains('amazon')) return 'Shopping';

    if (normalized.contains('current bill') ||
        normalized.contains('water bill'))
      return 'Bills & Utilities';
    if (normalized.contains('tneb') || normalized.contains('tangedco'))
      return 'Bills & Utilities';

    // Single keywords with word boundaries (Medium priority)
    final words = normalized.split(' ');

    for (final word in words) {
      if ([
        'restaurant',
        'food',
        'cafe',
        'cate',
        'coffee',
        'hotel',
        'swiggy',
        'zomato',
      ].contains(word))
        return 'Food & Dining';
      if ([
        'transport',
        'transpo',
        'bus',
        'train',
        'taxi',
        'uber',
        'ola',
        'auto',
        'metro',
        'cumta',
      ].contains(word))
        return 'Transport';
      if ([
        'recharge',
        'electricity',
        'gas',
        'lpg',
        'broadband',
        'dth',
        'jio',
        'airtel',
        'vi',
        'bsnl',
      ].contains(word))
        return 'Bills & Utilities';
      if ([
        'grocery',
        'supermarket',
        'mart',
        'store',
        'kirana',
        'dairy',
      ].contains(word))
        return 'Groceries';
      if ([
        'hospital',
        'clinic',
        'pharmacy',
        'medical',
        'doctor',
        'meds',
      ].contains(word))
        return 'Health';
      if ([
        'movie',
        'cinema',
        'games',
        'entertainment',
        'ticket',
      ].contains(word))
        return 'Entertainment';
      if (['shopping', 'mall', 'cloth', 'apparel', 'shoes'].contains(word))
        return 'Shopping';
    }

    return null;
  }

  static String? _findCategoryByName(
    String name,
    String type,
    CategoryProvider provider,
  ) {
    final list = type.toUpperCase() == 'CREDIT'
        ? provider.incomeCategories
        : provider.expenseCategories;
    try {
      final category = list.firstWhere(
        (c) => c.name.toLowerCase() == name.toLowerCase(),
      );
      return category.id;
    } catch (e) {
      return null;
    }
  }

  static String? _getOtherCategoryId(String type, CategoryProvider provider) {
    if (type.toUpperCase() == 'CREDIT') {
      return _findCategoryByName('Other Income', type, provider);
    }
    return _findCategoryByName('Other', type, provider);
  }
}
