import 'package:flutter/material.dart';
import 'package:keybz/widgets/app_keyboard/app_keyboard.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/theme/spendz_colors.dart';
import '../../app/theme/spendz_typography.dart';
import '../../features/wallet/security/secure_number_service.dart';
import '../../features/wallet/security/wallet_key_service.dart';
import '../../models/wallet_card_model.dart';
import '../../models/wallet_document_model.dart';
import '../../providers/wallet_card_provider.dart';
import '../../providers/wallet_document_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/design_system/empty_state.dart';
import '../../widgets/design_system/primary_button.dart';
import 'card_detail_screen.dart';
import 'document_creation_screen.dart';
import 'document_preview_screen.dart';

/// Unified Studio Card Item representing either a payment card or an identity document.
enum StudioCardType { payment, document }

class StudioCardItem {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final StudioCardType type;
  final WalletCardModel? paymentCard;
  final WalletDocumentModel? document;
  final bool isFavorite;
  final String maskedNumber;
  final DateTime updatedAt;

  StudioCardItem.fromCard(WalletCardModel c)
    : id = c.id,
      title = c.nickname.isNotEmpty ? c.nickname : c.issuerName,
      subtitle =
          '${c.issuerName} • ${c.cardType.toUpperCase()} •••• ${c.lastFour}',
      category = c.cardType.toLowerCase(),
      type = StudioCardType.payment,
      paymentCard = c,
      document = null,
      isFavorite = c.isFavorite,
      maskedNumber = c.lastFour.isNotEmpty
          ? '•••• •••• •••• ${c.lastFour}'
          : c.maskedNumber,
      updatedAt = c.updatedAt;

  StudioCardItem.fromDocument(WalletDocumentModel d)
    : id = d.id,
      title = d.documentName,
      subtitle =
          '${d.category.replaceAll('_', ' ').toUpperCase()} • ${d.holderName ?? ''}',
      category = d.category.toLowerCase(),
      type = StudioCardType.document,
      paymentCard = null,
      document = d,
      isFavorite = d.isFavorite,
      maskedNumber = d.maskedIdentifier ?? '',
      updatedAt = d.updatedAt;
}

class CardsScreen extends StatefulWidget {
  final bool openAddDialog;

  const CardsScreen({super.key, this.openAddDialog = false});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> with WidgetsBindingObserver {
  String _selectedFilter = 'all';
  final SecureNumberService _secureNumberService = SecureNumberService();

  @override
  void initState() {
    super.initState();
    if (widget.openAddDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddCardDialog(context);
      });
    }
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.getSurface(context),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedSheet),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add to Wallet',
                      style: AppTextStyles.getHeading2(
                        context,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.credit_card_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  title: const Text(
                    'Add Payment Card',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Debit, credit, ATM, or membership card',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAddCardDialog(context);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF138808).withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.badge_outlined,
                      color: Color(0xFF138808),
                    ),
                  ),
                  title: const Text(
                    'Add Identity or Document Card',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Aadhaar, PAN, Driving Licence, Passport, RC, Insurance',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DocumentCreationScreen(),
                      ),
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

  void _showAddCardDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nicknameController = TextEditingController();
    final issuerController = TextEditingController();
    final cardholderController = TextEditingController();
    final lastFourController = TextEditingController();
    final fullNumberController = TextEditingController();
    int expiryMonth = 12;
    int expiryYear = 28;
    String cardType = 'credit';
    String cardNetwork = 'visa';
    String themeGradient = 'midnight_emerald';
    String cardLayoutId = 'minimal_luxury';

    final cardTypes = [
      'credit',
      'debit',
      'atm',
      'membership',
      'loyalty',
      'custom',
    ];
    final networks = ['visa', 'mastercard', 'rupay', 'amex'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getSurface(context),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedSheet),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.only(
                bottom: bottomInset + AppSpacing.card,
                left: AppSpacing.card,
                right: AppSpacing.card,
                top: AppSpacing.card,
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
                          Text(
                            'Add Payment Card',
                            style: AppTextStyles.getHeading2(
                              context,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.getPrimary(context).withAlpha(15),
                          borderRadius: AppRadius.roundedMd,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              color: AppColors.getPrimary(context),
                              size: 18,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Spendz never stores CVVs or PINs. Stored full numbers are AES-256-GCM encrypted and revealed only via biometrics.',
                                style: AppTextStyles.getBodySmall(
                                  context,
                                ).copyWith(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextFormField(
                        controller: nicknameController,
                        decoration: const InputDecoration(
                          labelText: 'Card Nickname (e.g. Daily Spender)',
                          prefixIcon: Icon(Icons.label_outline, size: 18),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextFormField(
                              controller: issuerController,
                              decoration: const InputDecoration(
                                labelText: 'Bank / Issuer (e.g. HDFC)',
                                prefixIcon: Icon(
                                  Icons.account_balance_outlined,
                                  size: 18,
                                ),
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: cardType,
                              decoration: const InputDecoration(
                                labelText: 'Card Type',
                              ),
                              items: cardTypes.map((t) {
                                return DropdownMenuItem(
                                  value: t,
                                  child: Text(t.toUpperCase()),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() => cardType = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextFormField(
                        controller: cardholderController,
                        decoration: const InputDecoration(
                          labelText: 'Cardholder Name',
                          prefixIcon: Icon(Icons.person_outline, size: 18),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextFormField(
                              controller: lastFourController,
                              decoration: const InputDecoration(
                                labelText: 'Last 4 Digits',
                                hintText: '4821',
                                prefixIcon: Icon(Icons.credit_card, size: 18),
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              validator: (v) {
                                if (v == null || v.length != 4) {
                                  return 'Enter 4 digits';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: cardNetwork,
                              decoration: const InputDecoration(
                                labelText: 'Network',
                              ),
                              items: networks.map((net) {
                                return DropdownMenuItem(
                                  value: net,
                                  child: Text(net.toUpperCase()),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() => cardNetwork = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextFormField(
                        controller: fullNumberController,
                        decoration: const InputDecoration(
                          labelText:
                              'Full Card Number (Encrypted Hardware Storage)',
                          hintText: 'Optional — for biometric tap reveal',
                          prefixIcon: Icon(
                            Icons.lock_outline_rounded,
                            size: 18,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: expiryMonth,
                              decoration: const InputDecoration(
                                labelText: 'Exp Month',
                              ),
                              items: List.generate(12, (i) => i + 1).map((m) {
                                return DropdownMenuItem(
                                  value: m,
                                  child: Text(m.toString().padLeft(2, '0')),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() => expiryMonth = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: expiryYear,
                              decoration: const InputDecoration(
                                labelText: 'Exp Year',
                              ),
                              items: List.generate(15, (i) => 24 + i).map((y) {
                                return DropdownMenuItem(
                                  value: y,
                                  child: Text('20$y'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() => expiryYear = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      const SizedBox(height: AppSpacing.xl),
                      PrimaryButton(
                        label: 'Save Card to Wallet',
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            final cardProvider = context
                                .read<WalletCardProvider>();
                            final walletProvider = context
                                .read<WalletProvider>();
                            final messenger = ScaffoldMessenger.of(context);

                            final last4 = lastFourController.text.trim();
                            final cardId = const Uuid().v4();

                            final rawFull = fullNumberController.text.trim();
                            if (rawFull.isNotEmpty) {
                              try {
                                await _secureNumberService.saveCardFullNumber(
                                  cardId,
                                  rawFull,
                                );
                              } catch (_) {
                                try {
                                  final keyService = WalletKeyService();
                                  await keyService
                                      .resetAndRegenerateMasterKey();
                                  await _secureNumberService.saveCardFullNumber(
                                    cardId,
                                    rawFull,
                                  );
                                } catch (_) {}
                              }
                            }

                            final card = WalletCardModel(
                              id: cardId,
                              nickname: nicknameController.text.trim(),
                              issuerName: issuerController.text.trim(),
                              cardholderName: cardholderController.text.trim(),
                              maskedNumber: '•••• •••• •••• $last4',
                              lastFour: last4,
                              expiryMonth: expiryMonth,
                              expiryYear: expiryYear,
                              cardType: cardType,
                              cardNetwork: cardNetwork,
                              themeGradient: themeGradient,
                              cardLayoutId: cardLayoutId,
                              isFavorite: false,
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            );

                            await cardProvider.addCard(card);
                            if (mounted) {
                              walletProvider.loadWallet();
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                              }
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Card added to Wallet.'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          }
                        },
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

  void _openCardItem(BuildContext context, StudioCardItem item) {
    if (item.type == StudioCardType.payment && item.paymentCard != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CardDetailScreen(card: item.paymentCard!),
        ),
      );
    } else if (item.type == StudioCardType.document && item.document != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DocumentPreviewScreen(document: item.document!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4D2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F4D2),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2C221E)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Wallet Cards',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2C221E),
              ),
            ),
            const Text(
              'Your saved cards and official documents',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                color: Color(0xFF63564F),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add_circle_outline,
              color: AppColors.getPrimary(context),
            ),
            tooltip: 'Add Card',
            onPressed: () => _showAddOptions(context),
          ),
        ],
      ),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, child) {
          final paymentItems = wallet.cards
              .map((c) => StudioCardItem.fromCard(c))
              .toList();
          final documentItems = wallet.documents
              .map((d) => StudioCardItem.fromDocument(d))
              .toList();
          final allCards = [...paymentItems, ...documentItems];

          final govtCategories = {
            'aadhaar',
            'pan',
            'driving_license',
            'passport',
            'voter_id',
          };
          final rcInsuranceCategories = {'rc', 'insurance'};

          List<StudioCardItem> filteredCards;
          switch (_selectedFilter) {
            case 'govt_id':
              filteredCards = allCards
                  .where((c) => govtCategories.contains(c.category))
                  .toList();
              break;
            case 'payment':
              filteredCards = allCards
                  .where((c) => c.type == StudioCardType.payment)
                  .toList();
              break;
            case 'rc_insurance':
              filteredCards = allCards
                  .where((c) => rcInsuranceCategories.contains(c.category))
                  .toList();
              break;
            case 'favorite':
              filteredCards = allCards.where((c) => c.isFavorite).toList();
              break;
            case 'all':
            default:
              filteredCards = allCards;
              break;
          }

          return Column(
            children: [
              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    _buildFilterChip('all', 'All Cards (${allCards.length})'),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('govt_id', 'Govt IDs'),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('payment', 'Payment Cards'),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('rc_insurance', 'RC & Insurance'),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('favorite', 'Favorites'),
                  ],
                ),
              ),

              // Wallet records use a compact list for quick scanning.
              Expanded(
                child: filteredCards.isEmpty
                    ? EmptyState(
                        icon: Icons.credit_card_off_rounded,
                        title: 'No wallet items',
                        message:
                            'Add a payment card or official document to get started.',
                        actionLabel: 'Add to Wallet',
                        onAction: () => _showAddOptions(context),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        itemCount: filteredCards.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) =>
                            _buildCardItemWidget(filteredCards[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() {
        _selectedFilter = key;
      }),
      selectedColor: AppColors.getPrimary(context).withAlpha(40),
      labelStyle: TextStyle(
        color: isSelected
            ? AppColors.getPrimary(context)
            : AppColors.getTextSecondary(context),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  Widget _buildCardItemWidget(StudioCardItem item, {VoidCallback? onTap}) {
    final isPaymentCard = item.type == StudioCardType.payment;
    final category = item.category.toLowerCase();
    final imageAsset = isPaymentCard
        ? 'assets/credit_Debit.png'
        : category.contains('aadhaar')
        ? 'assets/aadhar.png'
        : category.contains('pan')
        ? 'assets/PAN.png'
        : category.contains('voter')
        ? 'assets/voterid.png'
        : category.contains('passport')
        ? 'assets/passport.jpeg'
        : category.contains('licen') || category.contains('driv')
        ? 'assets/licence.png'
        : category.contains('insur')
        ? 'assets/Insurance.png'
        : null;

    return Container(
      decoration: BoxDecoration(
        color: SpendzColors.cream,
        borderRadius: BorderRadius.circular(14),
        boxShadow: SpendzColors.clayDropShadow(context, blur: 4),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap ?? () => _openCardItem(context, item),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: SpendzColors.pistachio,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: imageAsset == null
                      ? const Icon(Icons.description_outlined)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            imageAsset,
                            width: 34,
                            height: 34,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.credit_card_rounded,
                              color: SpendzColors.espresso,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w800,
                          color: SpendzColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SpendzTypography.caption(context),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: item.isFavorite ? 'Remove favorite' : 'Add favorite',
                  onPressed: () {
                    if (isPaymentCard) {
                      context.read<WalletCardProvider>().toggleCardFavorite(
                        item.id,
                      );
                    } else {
                      context
                          .read<WalletDocumentProvider>()
                          .toggleDocumentFavorite(item.id);
                    }
                    context.read<WalletProvider>().loadWallet();
                  },
                  icon: Icon(
                    item.isFavorite ? Icons.star_rounded : Icons.star_outline,
                    color: item.isFavorite
                        ? SpendzColors.terracotta
                        : SpendzColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
