import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_text_styles.dart';
import '../../providers/wallet_document_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/design_system/empty_state.dart';
import 'document_creation_screen.dart';
import 'document_preview_screen.dart';
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
  String _selectedCategory = 'all';
  String _selectedFilter = 'all'; // 'all', 'favorites', 'expiring', 'recent'
  String _searchQuery = '';
  bool _isCardView = true;

  @override
  void initState() {
    super.initState();
    if (widget.openAddDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToAddDocument();
      });
    }
  }

  void _navigateToAddDocument() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DocumentCreationScreen()),
    );
  }

  bool _matchesCategory(String docCategory, String selected) {
    if (selected == 'all') return true;
    final cat = docCategory.toLowerCase();

    switch (selected) {
      case 'identity':
        return cat == 'aadhaar' || cat == 'pan' || cat == 'voter_id' || cat == 'college_id';
      case 'banking':
        return cat == 'debit_card' || cat == 'credit_card' || cat == 'bank_document';
      case 'driving':
        return cat == 'driving_license' || cat == 'rc';
      case 'travel':
        return cat == 'passport';
      case 'insurance':
        return cat == 'insurance';
      case 'others':
        return cat == 'other' || cat == 'certificate';
      default:
        return cat == selected;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('My Documents'),
        actions: [
          IconButton(
            icon: Icon(_isCardView ? Icons.view_list_rounded : Icons.view_agenda_rounded),
            tooltip: _isCardView ? 'Switch to List View' : 'Switch to Virtual Card View',
            onPressed: () => setState(() => _isCardView = !_isCardView),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            tooltip: 'Add Document',
            onPressed: _navigateToAddDocument,
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
        onPressed: _navigateToAddDocument,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Document'),
      ),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, _) {
          if (wallet.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final allDocs = wallet.documents;

          // Apply filtering
          final filteredDocs = allDocs.where((doc) {
            final matchesCat = _matchesCategory(doc.category, _selectedCategory);
            final matchesSearch = _searchQuery.isEmpty ||
                doc.documentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (doc.holderName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                (doc.maskedIdentifier?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                (doc.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

            bool matchesFilter = true;
            if (_selectedFilter == 'favorites') {
              matchesFilter = doc.isFavorite;
            } else if (_selectedFilter == 'expiring') {
              matchesFilter = doc.isExpiringSoon || doc.isExpired;
            } else if (_selectedFilter == 'recent') {
              final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
              matchesFilter = doc.createdAt.isAfter(sevenDaysAgo);
            }

            return matchesCat && matchesSearch && matchesFilter;
          }).toList();

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search documents, holders, or numbers...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.getTextSecondary(context)),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.getSurface(context),
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: AppColors.getBorder(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: AppColors.getBorder(context)),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xs),

              // Category Navigation Chips
              DocumentCategoryChips(
                selectedCategory: _selectedCategory,
                onSelected: (cat) => setState(() => _selectedCategory = cat),
              ),

              const SizedBox(height: AppSpacing.xs),

              // Quick Filter Tabs (All, Favorites, Expiring, Recent)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    _filterTab('All', 'all', allDocs.length),
                    const SizedBox(width: AppSpacing.sm),
                    _filterTab('Favorites', 'favorites', allDocs.where((d) => d.isFavorite).length),
                    const SizedBox(width: AppSpacing.sm),
                    _filterTab('Expiring', 'expiring', allDocs.where((d) => d.isExpiringSoon || d.isExpired).length),
                    const SizedBox(width: AppSpacing.sm),
                    _filterTab('Recent', 'recent', null),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Document Presentation (Cards or List)
              Expanded(
                child: filteredDocs.isEmpty
                    ? _buildEmptyView()
                    : (_isCardView
                        ? _buildCardGrid(filteredDocs)
                        : _buildListView(filteredDocs)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filterTab(String label, String key, int? count) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withAlpha(20) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.getTextSecondary(context),
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.grey.withAlpha(50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.getTextSecondary(context),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCardGrid(List<dynamic> docs) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      itemCount: docs.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final doc = docs[index];
        return VirtualDocumentCard(
          document: doc,
          showShadow: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DocumentPreviewScreen(document: doc)),
            );
          },
          onFavoriteToggle: () {
            context.read<WalletDocumentProvider>().toggleDocumentFavorite(doc.id);
          },
        );
      },
    );
  }

  Widget _buildListView(List<dynamic> docs) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      itemCount: docs.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final doc = docs[index];
        return DocumentVaultTile(
          document: doc,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DocumentPreviewScreen(document: doc)),
            );
          },
          onFavoriteToggle: () {
            context.read<WalletDocumentProvider>().toggleDocumentFavorite(doc.id);
          },
        );
      },
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: EmptyState(
        icon: Icons.folder_open_outlined,
        title: _searchQuery.isNotEmpty ? 'No Matching Documents' : 'No Documents in Vault',
        subtitle: _searchQuery.isNotEmpty
            ? 'Try adjusting your search terms or category filter.'
            : 'Tap Add Document to manually store your digital IDs, cards, licences, and insurance policies with military-grade encryption.',
        actionLabel: 'Add Document',
        onActionPressed: _navigateToAddDocument,
      ),
    );
  }
}
