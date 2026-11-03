import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../providers/wallet_provider.dart';
import '../../models/wallet_pass_model.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

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

    final passTypes = ['qr_code', 'barcode', 'event_ticket', 'boarding_pass', 'membership', 'loyalty'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Add Digital Pass', style: AppTextStyles.heading3),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Pass Title (e.g. Metro Smart Card)',
                          prefixIcon: Icon(Icons.confirmation_number_outlined),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: passType,
                        decoration: const InputDecoration(labelText: 'Pass Type'),
                        items: passTypes.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Text(t.replaceAll('_', ' ').toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => passType = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: dataController,
                        decoration: const InputDecoration(
                          labelText: 'Code / QR Payload',
                          prefixIcon: Icon(Icons.qr_code_2),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: issuerController,
                        decoration: const InputDecoration(
                          labelText: 'Issuer / Organizer (Optional)',
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Valid Until', style: TextStyle(fontSize: 12, color: Colors.white70)),
                        subtitle: Text(
                          validUntil != null ? DateFormat('dd MMM yyyy, HH:mm').format(validUntil!) : 'No Expiry',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.calendar_today, size: 18),
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                          );
                          if (d != null) setModalState(() => validUntil = d);
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              final pass = WalletPassModel(
                                id: const Uuid().v4(),
                                title: titleController.text.trim(),
                                passType: passType,
                                encryptedCodePath: dataController.text.trim(),
                                codeFormat: 'QR_CODE',
                                issuer: issuerController.text.trim().isEmpty ? null : issuerController.text.trim(),
                                validUntil: validUntil,
                                isFavorite: false,
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now(),
                              );

                              context.read<WalletProvider>().addPass(pass);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Pass saved to wallet!')),
                              );
                            }
                          },
                          child: const Text('Save Digital Pass'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPassQR(BuildContext context, WalletPassModel pass) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(pass.title, style: AppTextStyles.heading3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_2_rounded, size: 160, color: Colors.black),
                  const SizedBox(height: 8),
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
            const SizedBox(height: 16),
            if (pass.issuer != null)
              Text(
                'Issued by ${pass.issuer}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            if (pass.validUntil != null)
              Text(
                'Valid until ${DateFormat('dd MMM yyyy').format(pass.validUntil!)}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<WalletProvider>().deletePass(pass.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete Pass', style: TextStyle(color: Colors.redAccent)),
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
      appBar: AppBar(
        title: const Text('Digital Passes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.confirmation_number_outlined, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text('No Passes Saved', style: AppTextStyles.heading3),
                  const SizedBox(height: 8),
                  const Text('Save tickets, boarding passes, or transit QR codes.', style: TextStyle(color: Colors.white54)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _showAddPassDialog(context),
                    child: const Text('Add Pass'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: passes.length,
            itemBuilder: (context, index) {
              final pass = passes[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withAlpha(25)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.qr_code_2, color: AppColors.primary, size: 28),
                  ),
                  title: Text(pass.title, style: AppTextStyles.labelLarge),
                  subtitle: Text(
                    '${pass.issuer ?? 'Pass'} • ${pass.passType.toUpperCase()}',
                    style: AppTextStyles.bodySmall,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          pass.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: pass.isFavorite ? Colors.amber : Colors.white38,
                        ),
                        onPressed: () => wallet.togglePassFavorite(pass.id),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white38),
                    ],
                  ),
                  onTap: () => _showPassQR(context, pass),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
