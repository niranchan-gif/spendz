import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../features/wallet/services/document_vault_service.dart';
import '../../features/wallet/services/document_expiry_service.dart';
import '../../models/wallet_document_model.dart';
import '../../providers/wallet_document_provider.dart';
import '../../providers/wallet_provider.dart';
import 'document_preview_screen.dart';
import 'document_scanner_screen.dart';
import 'wallet_security_settings_screen.dart';
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
  String _selectedCategory = 'all';
  String _searchQuery = '';

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
                          Text('Add Document to Vault', style: AppTextStyles.heading3),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: isEncrypting ? null : () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withAlpha(40)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.shield_outlined, color: AppColors.primary, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Documents are encrypted with AES-256-GCM before saving locally.',
                                style: TextStyle(fontSize: 11, color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Document Name (e.g. My Aadhaar)',
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: categories.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(cat.replaceAll('_', ' ').toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => category = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: 'Description / ID (Optional)',
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Issue Date', style: TextStyle(fontSize: 12, color: Colors.white70)),
                              subtitle: Text(
                                issueDate != null ? DateFormat('dd MMM yyyy').format(issueDate!) : 'Select Date',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              trailing: const Icon(Icons.calendar_today, size: 18),
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Expiry Date', style: TextStyle(fontSize: 12, color: Colors.white70)),
                              subtitle: Text(
                                expiryDate != null ? DateFormat('dd MMM yyyy').format(expiryDate!) : 'No Expiry',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              trailing: const Icon(Icons.event_busy, size: 18),
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
                      const SizedBox(height: 12),
                      Text('Select Document File', style: AppTextStyles.labelLarge),
                      const SizedBox(height: 8),

                      // File picker trigger buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: mimeType.contains('pdf') ? AppColors.primary : Colors.white24,
                                ),
                              ),
                              icon: const Icon(Icons.picture_as_pdf, size: 18),
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
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: mimeType.contains('image') ? AppColors.primary : Colors.white24,
                                ),
                              ),
                              icon: const Icon(Icons.image, size: 18),
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

                      // Display chosen file badge
                      if (pickedFileName != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withAlpha(50)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  pickedFileName!,
                                  style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${((pickedFileBytes?.length ?? 0) / 1024).toStringAsFixed(0)} KB',
                                style: const TextStyle(fontSize: 10, color: Colors.white60),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isEncrypting
                              ? null
                              : () async {
                                  if (formKey.currentState!.validate()) {
                                    if (pickedFileBytes == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please select a PDF or Image file to import.')),
                                      );
                                      return;
                                    }

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

                                      if (!context.mounted) return;

                                      // Refresh providers
                                      await context.read<WalletProvider>().loadWallet();
                                      if (context.mounted) {
                                        await context.read<WalletDocumentProvider>().loadDocuments();
                                      }

                                      if (!ctx.mounted) return;
                                      Navigator.pop(ctx);

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('"${doc.documentName}" encrypted and saved to vault!'),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setModalState(() => isEncrypting = false);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Import failed: $e')),
                                        );
                                      }
                                    }
                                  }
                                },
                          child: isEncrypting
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Encrypting with AES-256-GCM...'),
                                  ],
                                )
                              : const Text('Encrypt & Save to Vault'),
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

  void _showDocumentDetails(BuildContext context, WalletDocumentModel doc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(doc.documentName, style: AppTextStyles.heading2),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withAlpha(40)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock, size: 10, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            'AES-256-GCM',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Category: ${doc.category.toUpperCase()}',
                  style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 13),
                ),
                if (doc.description != null && doc.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(doc.description!, style: AppTextStyles.bodyMedium),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Issue Date', style: TextStyle(fontSize: 11, color: Colors.white54)),
                          const SizedBox(height: 4),
                          Text(
                            doc.issueDate != null ? DateFormat('dd MMM yyyy').format(doc.issueDate!) : 'None',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Expiry Date', style: TextStyle(fontSize: 11, color: Colors.white54)),
                          const SizedBox(height: 4),
                          Text(
                            doc.expiryDate != null ? DateFormat('dd MMM yyyy').format(doc.expiryDate!) : 'No Expiry',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: doc.isExpired ? AppColors.error : (doc.isExpiringSoon ? Colors.orange : Colors.white),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Type', style: TextStyle(fontSize: 11, color: Colors.white54)),
                          const SizedBox(height: 4),
                          Text(
                            doc.mimeType.contains('pdf') ? 'PDF' : 'Image',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.lock_open_rounded, color: AppColors.primary),
                  title: const Text('Preview Decrypted Document'),
                  subtitle: const Text('Requires biometric or device passcode unlock'),
                  trailing: const Icon(Icons.fingerprint, color: AppColors.primary),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DocumentPreviewScreen(document: doc),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.error),
                  title: const Text('Delete from Vault', style: TextStyle(color: AppColors.error)),
                  subtitle: const Text('Removes encrypted file and metadata'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _vaultService.deleteDocument(doc.id);
                    await DocumentExpiryService().cancelRemindersForDocument(doc.id);
                    if (context.mounted) {
                      await context.read<WalletProvider>().loadWallet();
                    }
                    if (context.mounted) {
                      await context.read<WalletDocumentProvider>().loadDocuments();
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Document deleted from vault.')),
                      );
                    }
                  },
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Document Vault'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
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
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Document',
            onPressed: () => _showAddDocumentDialog(context),
          ),
        ],
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search documents in vault...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),

              // Category Filter Bar
              DocumentCategoryChips(
                selectedCategory: _selectedCategory,
                onSelected: (cat) => setState(() => _selectedCategory = cat),
              ),

              const SizedBox(height: 8),

              // Expiring Documents Alert Banner
              if (wallet.expiringDocuments.isNotEmpty && _selectedCategory == 'all')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withAlpha(60)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${wallet.expiringDocuments.length} document(s) expiring soon or expired.',
                            style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Documents List
              Expanded(
                child: filteredDocs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shield_outlined, size: 64, color: Colors.white.withAlpha(60)),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty ? 'No documents in vault' : 'No matching documents',
                              style: AppTextStyles.heading3,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Tap + to encrypt and store personal IDs'
                                  : 'Try adjusting your search or category filter',
                              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white60),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          return DocumentVaultTile(
                            document: doc,
                            onTap: () => _showDocumentDetails(context, doc),
                            onFavoriteToggle: () {
                              context.read<WalletProvider>().toggleDocumentFavorite(doc.id);
                            },
                            onDelete: () async {
                              await _vaultService.deleteDocument(doc.id);
                              if (context.mounted) {
                                await context.read<WalletProvider>().loadWallet();
                              }
                            },
                          );
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
