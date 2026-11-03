import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/wallet_document_model.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

class DocumentVaultTile extends StatelessWidget {
  final WalletDocumentModel document;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onDelete;

  const DocumentVaultTile({
    super.key,
    required this.document,
    this.onTap,
    this.onFavoriteToggle,
    this.onDelete,
  });

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'aadhaar':
        return Icons.fingerprint_rounded;
      case 'pan':
        return Icons.badge_outlined;
      case 'driving_license':
        return Icons.drive_eta_outlined;
      case 'passport':
        return Icons.flight_takeoff_rounded;
      case 'rc':
        return Icons.directions_car_filled_outlined;
      case 'insurance':
        return Icons.verified_user_outlined;
      case 'college_id':
        return Icons.school_outlined;
      case 'certificate':
        return Icons.workspace_premium_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 KB';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = document.isExpired;
    final isExpiringSoon = document.isExpiringSoon;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isExpired 
              ? AppColors.error.withAlpha(100) 
              : (isExpiringSoon ? Colors.orange.withAlpha(100) : Colors.white.withAlpha(20)),
          width: 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withAlpha(50)),
              ),
              child: Icon(
                _getCategoryIcon(document.category),
                color: AppColors.primary,
                size: 24,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 10,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                document.documentName,
                style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (document.mimeType.contains('pdf'))
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PDF',
                  style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              document.description ?? document.category.toUpperCase(),
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  _formatFileSize(document.fileSize),
                  style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 11),
                ),
                const SizedBox(width: 8),
                Text(
                  '•',
                  style: TextStyle(color: Colors.white.withAlpha(80), fontSize: 11),
                ),
                const SizedBox(width: 8),
                if (document.expiryDate != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isExpired
                          ? AppColors.error.withAlpha(30)
                          : (isExpiringSoon ? Colors.orange.withAlpha(30) : Colors.white.withAlpha(15)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isExpired
                          ? 'Expired (${DateFormat('dd MMM yy').format(document.expiryDate!)})'
                          : (isExpiringSoon
                              ? 'Expires in ${document.expiryDate!.difference(DateTime.now()).inDays}d'
                              : 'Exp: ${DateFormat('dd MMM yy').format(document.expiryDate!)}'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isExpired
                            ? AppColors.error
                            : (isExpiringSoon ? Colors.orange : Colors.white70),
                      ),
                    ),
                  )
                else
                  Text(
                    'No Expiry',
                    style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 11),
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onFavoriteToggle != null)
              IconButton(
                icon: Icon(
                  document.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: document.isFavorite ? Colors.amber : Colors.white.withAlpha(120),
                  size: 22,
                ),
                onPressed: onFavoriteToggle,
              ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white54,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

