import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/gmail_import_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/imported_transaction.dart';
import '../../app/theme/spendz_colors.dart';
import '../../utils/icon_mapper.dart';
import '../../services/category_engine.dart';

class ImportedTransactionsScreen extends StatelessWidget {
  const ImportedTransactionsScreen({super.key});

  void _showCategoryPicker(
    BuildContext context,
    ImportedTransaction tx,
    CategoryProvider categoryProvider,
    GmailImportProvider importProvider,
  ) {
    final categories = tx.type.toUpperCase() == 'CREDIT'
        ? categoryProvider.incomeCategories
        : categoryProvider.expenseCategories;

    showModalBottomSheet(
      context: context,
      backgroundColor: SpendzColors.clayCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: SpendzColors.textSecondary(context).withAlpha(80),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Select Category',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: SpendzColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final catColor = Color(int.parse(cat.color));

                      return InkWell(
                        onTap: () {
                          importProvider.updateCategory(tx.reference, cat.id);
                          Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF0EBE1), width: 1),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: catColor.withAlpha(35),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(IconMapper.getIcon(cat.icon), color: catColor, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                cat.name,
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: SpendzColors.textPrimary(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpendzColors.background(context),
      body: SafeArea(
        child: Column(
          children: [
            // Funky Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: SpendzColors.clayCream,
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(12),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 20,
                            color: SpendzColors.textPrimary(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: SpendzColors.tangerine,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: SpendzColors.tangerine.withAlpha(100),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.asset('assets/icon.png', width: 22, height: 22),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'BANK SYNC',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Consumer2<GmailImportProvider, TransactionProvider>(
                    builder: (context, importProvider, txProvider, _) {
                      if (importProvider.newTransactions.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return GestureDetector(
                        onTap: () async {
                          final added = await importProvider.approveAll(txProvider);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added $added transactions to activity!'),
                                backgroundColor: const Color(0xFF0F5B38),
                              ),
                            );
                            Navigator.pop(context);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFCEF1DE),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFA5DFC0), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF70C99A).withAlpha(60),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF0F5B38)),
                              SizedBox(width: 4),
                              Text(
                                'Approve All',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F5B38),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Consumer3<GmailImportProvider, TransactionProvider, CategoryProvider>(
                builder: (context, importProvider, txProvider, categoryProvider, _) {
                  if (importProvider.isLoading) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: SpendzColors.tangerine.withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: SpendzColors.tangerine,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Syncing Bank & SMS Alerts...',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: SpendzColors.textPrimary(context),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (importProvider.error != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFECE9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.cloud_off_rounded, color: Color(0xFFBA1A1A), size: 28),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Sync Connection Failed',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: SpendzColors.textPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              importProvider.error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 12.5,
                                color: SpendzColors.textSecondary(context),
                              ),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => importProvider.reloadTransactions(categoryProvider),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                decoration: BoxDecoration(
                                  color: SpendzColors.tangerine,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Retry Sync',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final txList = importProvider.newTransactions;

                  if (txList.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                          decoration: BoxDecoration(
                            color: SpendzColors.clayCream,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: const Color(0xFFF0EBE1), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(12),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFCEF1DE),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF0F5B38), size: 30),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'All Caught Up!',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: SpendzColors.textPrimary(context),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'No pending bank or SMS transactions found.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: SpendzColors.textSecondary(context),
                                ),
                              ),
                              const SizedBox(height: 20),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: SpendzColors.tangerine,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: SpendzColors.tangerine.withAlpha(80),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'Back to Home',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    physics: const BouncingScrollPhysics(),
                    itemCount: txList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final tx = txList[index];
                      final isExpense = tx.type.toUpperCase() == 'DEBIT';
                      final isParent = CategoryEngine.isParentTransfer(tx.name);

                      final cat = tx.suggestedCategoryId != null
                          ? categoryProvider.getCategoryById(tx.suggestedCategoryId!)
                          : null;

                      final amountColor = isParent
                          ? SpendzColors.tertiarySky
                          : (isExpense ? const Color(0xFFBA1A1A) : const Color(0xFF0F5B38));
                      final amountPrefix = isExpense ? '-' : '+';

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: SpendzColors.clayCream,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFF0EBE1), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(12),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    tx.name,
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: SpendzColors.textPrimary(context),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$amountPrefix₹${tx.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: amountColor,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Category pill + Actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () => _showCategoryPicker(
                                    context,
                                    tx,
                                    categoryProvider,
                                    importProvider,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          cat != null
                                              ? IconMapper.getIcon(cat.icon)
                                              : Icons.category_rounded,
                                          size: 13,
                                          color: SpendzColors.textSecondary(context),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          cat?.name ?? 'Category',
                                          style: TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: SpendzColors.textPrimary(context),
                                          ),
                                        ),
                                        const SizedBox(width: 3),
                                        Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 14,
                                          color: SpendzColors.textSecondary(context),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    // Reject Button
                                    GestureDetector(
                                      onTap: () => importProvider.removeTransaction(tx),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFECE9),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          size: 15,
                                          color: Color(0xFFBA1A1A),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Approve Button
                                    GestureDetector(
                                      onTap: () async {
                                        await importProvider.approveTransaction(tx.reference, txProvider);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Transaction added!'),
                                              backgroundColor: Color(0xFF0F5B38),
                                            ),
                                          );
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFCEF1DE),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.check_rounded,
                                              size: 14,
                                              color: Color(0xFF0F5B38),
                                            ),
                                            SizedBox(width: 3),
                                            Text(
                                              'Add',
                                              style: TextStyle(
                                                fontFamily: 'Plus Jakarta Sans',
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF0F5B38),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
