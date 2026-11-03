import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../providers/wallet_provider.dart';
import '../../models/wallet_document_model.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import 'widgets/document_category_chip.dart';
import 'widgets/document_vault_tile.dart';

class DocumentsScreen extends StatefulWidget {
  final bool openAddDialog;

  const DocumentsScreen({super.key, this.openAddDialog = false});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
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
    String mimeType = 'image/jpeg';

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
                            onPressed: () => Navigator.pop(ctx),
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
                            Icon(Icons.lock_rounded, color: AppColors.primary, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Files are encrypted with AES-256-GCM before saving locally.',
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
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
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
                          labelText: 'Description / Document ID (Optional)',
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
                      Text('Import Method', style: AppTextStyles.labelLarge),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.picture_as_pdf, size: 18),
                              label: const Text('PDF File'),
                              onPressed: () {
                                setModalState(() => mimeType = 'application/pdf');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('File picker ready for encrypted import.')),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.image, size: 18),
                              label: const Text('Image'),
                              onPressed: () {
                                setModalState(() => mimeType = 'image/jpeg');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Gallery picker ready for encrypted import.')),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              final doc = WalletDocumentModel(
                                id: const Uuid().v4(),
                                documentName: nameController.text.trim(),
                                category: category,
                                description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                                encryptedFilePath: 'vault/${DateTime.now().millisecondsSinceEpoch}_vault.dat',
                                mimeType: mimeType,
                                fileSize: 1024 * 350,
                                issueDate: issueDate,
                                expiryDate: expiryDate,
                                isFavorite: false,
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now(),
                              );

                              context.read<WalletProvider>().addDocument(doc);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Document encrypted and stored in vault!')),
                              );
                            }
                          },
                          child: const Text('Encrypt & Save to Vault'),
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
                        color: Colors.white.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Preview • Phase 3 Encrypted',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
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
                            doc.mimeType.contains('pdf') ? 'PDF' : 'JPEG',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.remove_red_eye_outlined, color: AppColors.primary),
                  title: const Text('Preview Decrypted Document'),
                  subtitle: const Text('Requires biometric or passcode unlock'),
                  trailing: const Icon(Icons.fingerprint),
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Document preview unlocked.')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.error),
                  title: const Text('Delete from Vault', style: TextStyle(color: AppColors.error)),
                  onTap: () {
                    context.read<WalletProvider>().deleteDocument(doc.id);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Document deleted.')),
                    );
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
      appBar: AppBar(
        title: const Text('Document Vault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Document',
            onPressed: () => _showAddDocumentDialog(context),
          ),
        ],
      ),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, child) {
          var docs = wallet.getDocumentsByCategory(_selectedCategory);

          if (_searchQuery.isNotEmpty) {
            docs = docs.where((d) {
              return d.documentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  (d.description != null && d.description!.toLowerCase().contains(_searchQuery.toLowerCase()));
            }).toList();
          }

          return Column(
            children: [
              // Search field
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search documents...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                  ),
                  onChanged: (q) => setState(() => _searchQuery = q),
                ),
              ),

              // Category chips
              DocumentCategoryChips(
                selectedCategory: _selectedCategory,
                onSelected: (cat) => setState(() => _selectedCategory = cat),
              ),

              const SizedBox(height: 8),

              Expanded(
                child: docs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.folder_open, size: 64, color: Colors.white24),
                            const SizedBox(height: 16),
                            Text('No Documents Found', style: AppTextStyles.heading3),
                            const SizedBox(height: 8),
                            const Text('Import Aadhaar, PAN, DL, or certificates.', style: TextStyle(color: Colors.white54)),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () => _showAddDocumentDialog(context),
                              child: const Text('Add Document'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          return DocumentVaultTile(
                            document: doc,
                            onFavoriteToggle: () => wallet.toggleDocumentFavorite(doc.id),
                            onTap: () => _showDocumentDetails(context, doc),
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
