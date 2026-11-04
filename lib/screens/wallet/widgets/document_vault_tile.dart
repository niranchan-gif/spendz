import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/wallet_document_model.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_radius.dart';
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
      case 'debit_card':
        return Icons.credit_card_rounded;
      case 'credit_card':
        return Icons.credit_score_rounded;
      case 'aadhaar':
        return Icons.fingerprint_rounded;
      case 'pan':
        return Icons.badge_outlined;
      case 'driving_license':
        return Icons.drive_eta_outlined;
      case 'passport':
        return Icons.flight_takeoff_rounded;
      case 'voter_id':
        return Icons.how_to_vote_rounded;
      case 'rc':
        return Icons.directions_car_filled_outlined;
      case 'insurance':
        return Icons.verified_user_outlined;
      case 'bank_document':
        return Icons.account_balance_outlined;
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

    final surfaceColor = AppColors.getSurface(context);
    final borderColor = isExpired
        ? AppColors.error.withAlpha(120)
        : (isExpiringSoon ? AppColors.warning.withAlpha(120) : AppColors.getBorder(context));
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 4,
          ),
          leading: Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                  border: Border.all(color: AppColors.primary.withAlpha(50)),
                ),
                child: Icon(
                  _getCategoryIcon(document.category),
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    size: 9,
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
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (document.mimeType.contains('pdf'))
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(25),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    border: Border.all(color: AppColors.error.withAlpha(50)),
                  ),
                  child: Text(
                    'PDF',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 3),
              Text(
                document.holderName != null && document.maskedIdentifier != null
                    ? '${document.holderName} • ${document.maskedIdentifier}'
                    : (document.maskedIdentifier ?? document.holderName ?? (document.description ?? document.category.replaceAll('_', ' ').toUpperCase())),
                style: AppTextStyles.bodySmall.copyWith(
                  color: textSecondary,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text(
                    _formatFileSize(document.fileSize),
                    style: AppTextStyles.caption.copyWith(
                      color: textSecondary,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '•',
                    style: TextStyle(color: textSecondary, fontSize: 10),
                  ),
                  const SizedBox(width: 6),
                  if (document.expiryDate != null)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isExpired
                              ? AppColors.error.withAlpha(25)
                              : (isExpiringSoon ? AppColors.warning.withAlpha(25) : AppColors.primary.withAlpha(15)),
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Text(
                          isExpired
                              ? 'Expired (${DateFormat('dd MMM yy').format(document.expiryDate!)})'
                              : (isExpiringSoon
                                  ? 'Expires in ${document.expiryDate!.difference(DateTime.now()).inDays}d'
                                  : 'Exp: ${DateFormat('dd MMM yy').format(document.expiryDate!)}'),
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isExpired
                                ? AppColors.error
                                : (isExpiringSoon ? AppColors.warning : AppColors.primary),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                  else
                    Text(
                      'No Expiry',
                      style: AppTextStyles.caption.copyWith(
                        color: textSecondary,
                        fontSize: 10,
                      ),
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
                    color: document.isFavorite ? Colors.amber : textSecondary.withAlpha(120),
                    size: 20,
                  ),
                  onPressed: onFavoriteToggle,
                  splashRadius: 20,
                ),
              Icon(
                Icons.chevron_right_rounded,
                color: textSecondary.withAlpha(140),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
