import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_text_styles.dart';
import '../../features/wallet/services/document_vault_service.dart';
import '../../features/wallet/security/secure_number_service.dart';
import '../../providers/wallet_document_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/design_system/app_bottom_sheet.dart';
import '../../widgets/design_system/app_form_field.dart';
import '../../widgets/design_system/primary_button.dart';
import '../../widgets/design_system/empty_state.dart';
import 'document_preview_screen.dart';
import 'document_scanner_screen.dart';
import 'wallet_security_settings_screen.dart';
import 'widgets/virtual_document_card.dart';
import 'widgets/document_category_chip.dart';
import 'widgets/document_vault_tile.dart';

class DocumentsScreen extends StatefulWidget {
  final bool openAddDialog;

  const DocumentsScreen({super.key, this.openAddDialog = false});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final DocumentVaultService _vaultService = DocumentVaultService();
  final SecureNumberService _secureNumberService = SecureNumberService();
  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _isCardView = true;

  @override
  void initState() {
    super.initState();
    if (widget.openAddDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddDocumentDialog(context);
      });
    }
  }

  void _showAddDocumentDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final docNumberController = TextEditingController();
    String category = 'aadhaar';
    DateTime? issueDate;
    DateTime? expiryDate;
    String mimeType = 'application/pdf';
    Uint8List? pickedFileBytes;
    String? pickedFileName;
    bool isEncrypting = false;

    final categories = [
      'aadhaar',
      'pan',
      'driving_license',
      'passport',
      'rc',
      'insurance',
      'college_id',
      'certificate',
      'other',
    ];

    AppBottomSheet.show(
      context: context,
      title: 'Add Document to Vault',
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
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm + 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: AppColors.primary.withAlpha(50)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_rounded, color: AppColors.primary, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Documents & sensitive IDs are hardware-encrypted with AES-256-GCM before saving locally.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppFormField(
                  controller: nameController,
                  label: 'Document Name',
                  hint: 'e.g. My Aadhaar Card',
                  prefixIcon: Icons.description_outlined,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Document name required' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  dropdownColor: surfaceColor,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    prefixIcon: const Icon(Icons.category_outlined),
                    filled: true,
                    fillColor: surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: AppColors.getBorder(context)),
                    ),
                  ),
                  items: categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(
                        cat.replaceAll('_', ' ').toUpperCase(),
                        style: AppTextStyles.labelMedium,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => category = val);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppFormField(
                  controller: docNumberController,
                  label: 'Sensitive ID Number (Encrypted Hardware Storage)',
                  hint: 'e.g. 12-digit Aadhaar / 10-char PAN',
                  prefixIcon: Icons.pin_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                AppFormField(
                  controller: descController,
                  label: 'Notes / Description (Optional)',
                  hint: 'e.g. Verified copy from DigiLocker',
                  prefixIcon: Icons.notes_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Issue Date', style: AppTextStyles.caption.copyWith(color: textSecondary)),
                        subtitle: Text(
                          issueDate != null ? DateFormat('dd MMM yyyy').format(issueDate!) : 'Select Date',
                          style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.calendar_today_rounded, size: 16),
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: issueDate ?? DateTime.now(),
                            firstDate: DateTime(1970),
                            lastDate: DateTime.now(),
                          );
                          if (d != null) setModalState(() => issueDate = d);
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Expiry Date', style: AppTextStyles.caption.copyWith(color: textSecondary)),
                        subtitle: Text(
                          expiryDate != null ? DateFormat('dd MMM yyyy').format(expiryDate!) : 'No Expiry',
                          style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.event_busy_rounded, size: 16),
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: expiryDate ?? DateTime.now().add(const Duration(days: 365)),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 20)),
                          );
                          if (d != null) setModalState(() => expiryDate = d);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Select Document File', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: mimeType.contains('pdf') ? AppColors.primary : AppColors.getBorder(context),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                        label: const Text('Pick PDF'),
                        onPressed: isEncrypting
                            ? null
                            : () async {
                                final files = await FilePicker.pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: ['pdf'],
                                );
                                if (files.isNotEmpty) {
                                  final file = files.first;
                                  final bytes = await file.readAsBytes();
                                  setModalState(() {
                                    pickedFileBytes = bytes;
                                    pickedFileName = file.name;
                                    mimeType = 'application/pdf';
                                    if (nameController.text.trim().isEmpty) {
                                      nameController.text = file.name.replaceAll('.pdf', '');
                                    }
                                  });
                                }
                              },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: mimeType.contains('image') ? AppColors.primary : AppColors.getBorder(context),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        icon: const Icon(Icons.image_rounded, size: 18),
                        label: const Text('Pick Image'),
                        onPressed: isEncrypting
                            ? null
                            : () async {
                                final files = await FilePicker.pickFiles(
                                  type: FileType.image,
                                );
                                if (files.isNotEmpty) {
                                  final file = files.first;
                                  final bytes = await file.readAsBytes();
                                  final ext = file.extension?.toLowerCase() ?? 'jpg';
                                  setModalState(() {
                                    pickedFileBytes = bytes;
                                    pickedFileName = file.name;
                                    mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
                                    if (nameController.text.trim().isEmpty) {
                                      nameController.text = file.name.replaceAll(RegExp(r'\.[a-zA-Z]+$'), '');
                                    }
                                  });
                                }
                              },
                      ),
                    ),
                  ],
                ),
                if (pickedFileName != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withAlpha(20),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.success.withAlpha(50)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 16),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            pickedFileName!,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${((pickedFileBytes?.length ?? 0) / 1024).toStringAsFixed(0)} KB',
                          style: AppTextStyles.caption.copyWith(color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: 'Encrypt & Save to Vault',
                  isLoading: isEncrypting,
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      if (pickedFileBytes == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select a PDF or Image file to import.')),
                        );
                        return;
                      }

                      final walletProvider = context.read<WalletProvider>();
                      final docProvider = context.read<WalletDocumentProvider>();
                      final messenger = ScaffoldMessenger.of(context);
                      final nav = Navigator.of(context);

                      setModalState(() => isEncrypting = true);

                      try {
                        final doc = await _vaultService.importDocument(
                          documentName: nameController.text.trim(),
                          category: category,
                          mimeType: mimeType,
                          fileBytes: pickedFileBytes!,
                          description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                          issueDate: issueDate,
                          expiryDate: expiryDate,
                        );

                        // Save sensitive document number in secure hardware storage if provided
                        final rawDocNum = docNumberController.text.trim();
                        if (rawDocNum.isNotEmpty) {
                          await _secureNumberService.saveDocumentFullNumber(doc.id, rawDocNum);
                        }

                        if (!mounted) return;
                        await walletProvider.loadWallet();
                        await docProvider.loadDocuments();

                        nav.pop();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('"${doc.documentName}" encrypted and saved to vault!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      } catch (e) {
                        setModalState(() => isEncrypting = false);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Import failed: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Document Vault'),
        actions: [
          IconButton(
            icon: Icon(_isCardView ? Icons.view_list_rounded : Icons.view_agenda_rounded),
            tooltip: _isCardView ? 'Switch to List View' : 'Switch to Virtual Card View',
            onPressed: () => setState(() => _isCardView = !_isCardView),
          ),
          IconButton(
            icon: const Icon(Icons.document_scanner_outlined, color: AppColors.primary),
            tooltip: 'Scan Document (OCR)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DocumentScannerScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.shield_outlined),
            tooltip: 'Vault Security Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WalletSecuritySettingsScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DocumentScannerScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.document_scanner_rounded),
        label: const Text('Scan Document'),
      ),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, _) {
          if (wallet.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final allDocs = wallet.documents;
          final filteredDocs = allDocs.where((doc) {
            final matchesCat = _selectedCategory == 'all' || doc.category.toLowerCase() == _selectedCategory;
            final matchesSearch = _searchQuery.isEmpty ||
                doc.documentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (doc.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
            return matchesCat && matchesSearch;
          }).toList();

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search documents in vault...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),

              const SizedBox(height: AppSpacing.xs),

              // Category Filter Bar
              DocumentCategoryChips(
                selectedCategory: _selectedCategory,
                onSelected: (cat) => setState(() => _selectedCategory = cat),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Expiring Documents Alert Banner
              if (wallet.expiringDocuments.isNotEmpty && _selectedCategory == 'all')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withAlpha(20),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.warning.withAlpha(60)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            '${wallet.expiringDocuments.length} document(s) expiring soon or expired.',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Documents List / Grid
              Expanded(
                child: filteredDocs.isEmpty
                    ? Center(
                        child: EmptyState(
                          icon: Icons.shield_outlined,
                          title: _searchQuery.isEmpty ? 'No Documents in Vault' : 'No Matching Documents',
                          subtitle: _searchQuery.isEmpty
                              ? 'Scan or import personal IDs, passports, cards and certificates.'
                              : 'Try adjusting your search query or category filters.',
                          actionLabel: _searchQuery.isEmpty ? 'Scan Document' : null,
                          onActionPressed: _searchQuery.isEmpty
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const DocumentScannerScreen()),
                                  );
                                }
                              : null,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 88),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          if (_isCardView) {
                            return VirtualDocumentCard(
                              document: doc,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => DocumentPreviewScreen(document: doc)),
                                );
                              },
                              onFavoriteToggle: () {
                                context.read<WalletProvider>().toggleDocumentFavorite(doc.id);
                              },
                            );
                          } else {
                            return DocumentVaultTile(
                              document: doc,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => DocumentPreviewScreen(document: doc)),
                                );
                              },
                              onFavoriteToggle: () {
                                context.read<WalletProvider>().toggleDocumentFavorite(doc.id);
                              },
                              onDelete: () async {
                                await _secureNumberService.deleteDocumentFullNumber(doc.id);
                                await _vaultService.deleteDocument(doc.id);
                                if (context.mounted) {
                                  await context.read<WalletProvider>().loadWallet();
                                }
                              },
                            );
                          }
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
