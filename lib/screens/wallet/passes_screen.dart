import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../providers/wallet_provider.dart';
import '../../models/wallet_pass_model.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_text_styles.dart';
import '../../widgets/design_system/app_bottom_sheet.dart';
import '../../widgets/design_system/app_form_field.dart';
import '../../widgets/design_system/primary_button.dart';
import '../../widgets/design_system/empty_state.dart';
import '../../widgets/design_system/custom_dialog.dart';
import 'widgets/transit_ticket_card.dart';

class PassesScreen extends StatefulWidget {
  final bool openAddDialog;

  const PassesScreen({super.key, this.openAddDialog = false});

  @override
  State<PassesScreen> createState() => _PassesScreenState();
}

class _PassesScreenState extends State<PassesScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.openAddDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddPassDialog(context);
      });
    }
  }

  void _showAddPassDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final dataController = TextEditingController();
    final issuerController = TextEditingController();
    String passType = 'qr_code';
    DateTime? validUntil;

    final passTypes = [
      'transit_ticket',
      'boarding_pass',
      'qr_code',
      'barcode',
      'event_ticket',
      'membership',
      'loyalty',
    ];

    AppBottomSheet.show(
      context: context,
      title: 'Add Digital Pass',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          final surfaceColor = AppColors.getSurface(context);
          final textSecondary = AppColors.getTextSecondary(context);

          return Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppFormField(
                  controller: titleController,
                  label: 'Pass Title',
                  hint: 'e.g. Metro Smart Card / Flight Boarding Pass',
                  prefixIcon: Icons.confirmation_number_outlined,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Pass title required'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: passType,
                  dropdownColor: surfaceColor,
                  decoration: InputDecoration(
                    labelText: 'Pass Type',
                    prefixIcon: const Icon(Icons.category_outlined),
                    filled: true,
                    fillColor: surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(
                        color: AppColors.getBorder(context),
                      ),
                    ),
                  ),
                  items: passTypes.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text(
                        t.replaceAll('_', ' ').toUpperCase(),
                        style: AppTextStyles.labelMedium,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => passType = val);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppFormField(
                  controller: dataController,
                  label: 'Code / QR Payload',
                  hint: 'Enter barcode or QR string',
                  prefixIcon: Icons.qr_code_2_rounded,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Payload code required'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AppFormField(
                  controller: issuerController,
                  label: 'Issuer / Organizer (Optional)',
                  hint: 'e.g. Indigo Airlines, BookMyShow',
                  prefixIcon: Icons.business_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Valid Until',
                    style: AppTextStyles.caption.copyWith(color: textSecondary),
                  ),
                  subtitle: Text(
                    validUntil != null
                        ? DateFormat('dd MMM yyyy, HH:mm').format(validUntil!)
                        : 'No Expiry',
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: const Icon(Icons.calendar_today_rounded, size: 18),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(
                        const Duration(days: 365 * 5),
                      ),
                    );
                    if (d != null) setModalState(() => validUntil = d);
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: 'Save Digital Pass',
                  icon: Icons.check_rounded,
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final pass = WalletPassModel(
                        id: const Uuid().v4(),
                        title: titleController.text.trim(),
                        passType: passType,
                        encryptedCodePath: dataController.text.trim(),
                        codeFormat: 'QR_CODE',
                        issuer: issuerController.text.trim().isEmpty
                            ? null
                            : issuerController.text.trim(),
                        validUntil: validUntil,
                        isFavorite: false,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );

                      context.read<WalletProvider>().addPass(pass);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pass saved to wallet!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPassQR(BuildContext context, WalletPassModel pass) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.getSurface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          pass.title,
          style: AppTextStyles.headingSmall.copyWith(
            color: AppColors.getTextPrimary(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.card),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: pass.codeData.isNotEmpty
                        ? pass.codeData
                        : 'spendz-pass',
                    version: QrVersions.auto,
                    size: 180.0,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    pass.codeData,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (pass.issuer != null)
              Text(
                'Issued by ${pass.issuer}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.getTextSecondary(context),
                ),
              ),
            if (pass.validUntil != null)
              Text(
                'Valid until ${DateFormat('dd MMM yyyy').format(pass.validUntil!)}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.getTextSecondary(context),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final walletProvider = context.read<WalletProvider>();
              final confirm = await CustomDialog.showConfirmation(
                context: ctx,
                title: 'Delete Pass?',
                message: 'Remove "${pass.title}" from your passes?',
                confirmLabel: 'Delete Pass',
                isDestructive: true,
                icon: Icons.delete_outline_rounded,
              );
              if (confirm == true && mounted) {
                if (ctx.mounted) Navigator.pop(ctx);
                walletProvider.deletePass(pass.id);
              }
            },
            child: const Text(
              'Delete Pass',
              style: TextStyle(color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Digital Passes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Pass',
            onPressed: () => _showAddPassDialog(context),
          ),
        ],
      ),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, child) {
          final passes = wallet.passes;

          if (passes.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.confirmation_number_outlined,
                title: 'No Passes Saved',
                subtitle:
                    'Save event tickets, flight boarding passes, and transit QR codes.',
                actionLabel: 'Add Digital Pass',
                onActionPressed: () => _showAddPassDialog(context),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            physics: const BouncingScrollPhysics(),
            itemCount: passes.length,
            itemBuilder: (context, index) {
              final pass = passes[index];

              if (pass.passType == 'transit_ticket' ||
                  pass.passType == 'boarding_pass') {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: TransitTicketCard(
                    pass: pass,
                    onDocUploaded: (path) async {
                      final updated = pass.copyWith(
                        encryptedCodePath: path,
                        notes: '${pass.notes ?? ""}\nDoc: $path',
                        updatedAt: DateTime.now(),
                      );
                      await context.read<WalletProvider>().updatePass(updated);
                    },
                    onDelete: () {
                      context.read<WalletProvider>().deletePass(pass.id);
                    },
                  ),
                );
              }

              final surfaceColor = AppColors.getSurface(context);
              final borderColor = AppColors.getBorder(context);

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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 4,
                    ),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                        border: Border.all(
                          color: AppColors.primary.withAlpha(50),
                        ),
                      ),
                      child: const Icon(
                        Icons.qr_code_2_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      pass.title,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                    subtitle: Text(
                      '${pass.issuer ?? 'Pass'} • ${pass.passType.toUpperCase()}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.getTextSecondary(context),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            pass.isFavorite
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: pass.isFavorite
                                ? Colors.amber
                                : AppColors.getTextSecondary(
                                    context,
                                  ).withAlpha(120),
                          ),
                          onPressed: () => wallet.togglePassFavorite(pass.id),
                          splashRadius: 20,
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.getTextSecondary(
                            context,
                          ).withAlpha(140),
                          size: 18,
                        ),
                      ],
                    ),
                    onTap: () => _showPassQR(context, pass),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
