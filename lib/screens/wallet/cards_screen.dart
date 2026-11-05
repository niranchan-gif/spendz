import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../../features/wallet/security/secure_number_service.dart';
import '../../features/wallet/security/wallet_auth_service.dart';
import '../../features/wallet/security/wallet_key_service.dart';
import '../../models/wallet_card_model.dart';
import '../../models/wallet_document_model.dart';
import '../../providers/wallet_card_provider.dart';
import '../../providers/wallet_document_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/design_system/empty_state.dart';
import '../../widgets/design_system/primary_button.dart';
import 'card_detail_screen.dart';
import 'card_studio/card_layout_sheet.dart';
import 'card_studio/card_studio_layout.dart';
import 'card_studio/card_studio_theme.dart';
import 'card_studio/card_theme_sheet.dart';
import 'card_studio/manage_cards_screen.dart';
import 'document_creation_screen.dart';
import 'document_preview_screen.dart';
import 'widgets/virtual_document_card.dart';
import 'widgets/wallet_card_widget.dart';

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
  late PageController _pageController;
  int _currentCardIndex = 0;
  bool _isStackedDeckView = true;

  // Biometric reveal state with auto-masking timer
  String? _revealedCardId;
  String? _revealedNumber;
  Timer? _maskTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(viewportFraction: 0.88);
    if (widget.openAddDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddCardDialog(context);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _remaskNumber();
    }
  }

  void _remaskNumber() {
    _maskTimer?.cancel();
    _maskTimer = null;
    if (mounted && _revealedCardId != null) {
      setState(() {
        _revealedCardId = null;
        _revealedNumber = null;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _maskTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _goToCard(int index, int total) {
    if (index >= 0 && index < total) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _revealActiveCardNumber(StudioCardItem item) async {
    final authService = context.read<WalletAuthService>();
    final authenticated = await authService.authenticate(
      localizedReason: 'Authenticate to view the complete card number',
    );

    if (!authenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authService.lastErrorMessage ??
                  'Biometric authentication required to reveal card number.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    String? fullNum;
    if (item.type == StudioCardType.payment) {
      fullNum = await _secureNumberService.getCardFullNumber(item.id);
      if (fullNum != null && fullNum.isNotEmpty) {
        fullNum = SecureNumberService.formatCardNumber(fullNum);
      }
    } else {
      fullNum = await _secureNumberService.getDocumentFullNumber(item.id);
    }

    if (fullNum == null || fullNum.isEmpty) {
      fullNum = item.maskedNumber;
    }

    if (mounted) {
      setState(() {
        _revealedCardId = item.id;
        _revealedNumber = fullNum;
      });

      _maskTimer?.cancel();
      _maskTimer = Timer(const Duration(seconds: 30), () {
        _remaskNumber();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Card number revealed (Auto-masks in 30 seconds)'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _copyActiveCardNumber(StudioCardItem item) async {
    final authService = context.read<WalletAuthService>();
    final authenticated = await authService.authenticate(
      localizedReason: 'Authenticate with biometrics to copy private number',
    );

    if (!authenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authService.lastErrorMessage ??
                  'Biometric authentication required to access private number.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    String numToCopy = item.maskedNumber;
    if (item.type == StudioCardType.payment) {
      final fullNum = await _secureNumberService.getCardFullNumber(item.id);
      if (fullNum != null && fullNum.isNotEmpty) {
        numToCopy = fullNum;
      }
    } else {
      final fullNum = await _secureNumberService.getDocumentFullNumber(item.id);
      if (fullNum != null && fullNum.isNotEmpty) {
        numToCopy = fullNum;
      }
    }

    await Clipboard.setData(ClipboardData(text: numToCopy));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied: $numToCopy'),
          backgroundColor: AppColors.primary,
        ),
      );
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
                      'Add to Card Studio',
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
                    'Debit, Credit, ATM or Membership Card with Custom Themes',
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
                            'Add Card to Studio',
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
                      TextFormField(
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
                            child: TextFormField(
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
                                if (val != null)
                                  setModalState(() => cardType = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
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
                            child: TextFormField(
                              controller: lastFourController,
                              decoration: const InputDecoration(
                                labelText: 'Last 4 Digits',
                                hintText: '4821',
                                prefixIcon: Icon(Icons.credit_card, size: 18),
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              validator: (v) {
                                if (v == null || v.length != 4)
                                  return 'Enter 4 digits';
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
                                if (val != null)
                                  setModalState(() => cardNetwork = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
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
                                if (val != null)
                                  setModalState(() => expiryMonth = val);
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
                                if (val != null)
                                  setModalState(() => expiryYear = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Card Theme Selection (8 themes)
                      Text('Card Theme', style: AppTextStyles.labelMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: CardStudioTheme.allThemes.map((th) {
                          final isSelected = themeGradient == th.id;
                          return ChoiceChip(
                            label: Text(th.name),
                            selected: isSelected,
                            avatar: CircleAvatar(
                              backgroundColor: th.primaryAccent,
                              radius: 6,
                            ),
                            onSelected: (_) =>
                                setModalState(() => themeGradient = th.id),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Card Layout Selection (5 layouts)
                      Text('Card Layout', style: AppTextStyles.labelMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: CardStudioLayout.allLayouts.map((lo) {
                          final isSelected = cardLayoutId == lo.id;
                          return ChoiceChip(
                            label: Text(lo.name),
                            selected: isSelected,
                            onSelected: (_) =>
                                setModalState(() => cardLayoutId = lo.id),
                          );
                        }).toList(),
                      ),

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
                                  content: Text('Card added to Card Studio!'),
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

  Color _getPeekCardColor(StudioCardItem item) {
    if (item.type == StudioCardType.payment && item.paymentCard != null) {
      final theme = CardStudioTheme.getTheme(item.paymentCard!.themeGradient);
      return theme.backgroundGradient.colors[1];
    }
    switch (item.category) {
      case 'aadhaar':
        return const Color(0xFFE65100);
      case 'pan':
        return const Color(0xFF004D40);
      case 'driving_license':
        return const Color(0xFF1565C0);
      case 'passport':
        return const Color(0xFF1A237E);
      default:
        return const Color(0xFF2E7D32);
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
              'Card Studio',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2C221E),
              ),
            ),
            const Text(
              'Premium Cards · Your Collection',
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
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Manage Cards & Reorder',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageCardsScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(
              _isStackedDeckView
                  ? Icons.view_agenda_outlined
                  : Icons.style_rounded,
              color: AppColors.getTextSecondary(context),
            ),
            tooltip: _isStackedDeckView
                ? 'Switch to List View'
                : 'Switch to Stacked Deck',
            onPressed: () =>
                setState(() => _isStackedDeckView = !_isStackedDeckView),
          ),
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

              // Cards Stack Carousel vs List View
              Expanded(
                child: filteredCards.isEmpty
                    ? EmptyState(
                        icon: Icons.credit_card_off_rounded,
                        title: 'No Cards in Studio',
                        message:
                            'Add payment cards, Aadhaar, PAN, DL, or Passport for unified tracking.',
                        actionLabel: 'Add Your First Card',
                        onAction: () => _showAddOptions(context),
                      )
                    : (_isStackedDeckView
                          ? _buildStackedCardDeck(context, filteredCards)
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.md,
                              ),
                              itemCount: filteredCards.length,
                              itemBuilder: (context, index) {
                                final item = filteredCards[index];
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md,
                                  ),
                                  child: Center(
                                    child: _buildCardItemWidget(item),
                                  ),
                                );
                              },
                            )),
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
        _currentCardIndex = 0;
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
    final isRevealed = _revealedCardId == item.id;
    final revealedNum = isRevealed ? _revealedNumber : null;

    if (item.type == StudioCardType.payment && item.paymentCard != null) {
      return WalletCardWidget(
        card: item.paymentCard!,
        allowReveal: false,
        revealedNumber: revealedNum,
        onTap: onTap ?? () => _openCardItem(context, item),
        onFavoriteToggle: () {
          context.read<WalletCardProvider>().toggleCardFavorite(item.id);
          context.read<WalletProvider>().loadWallet();
        },
      );
    } else if (item.document != null) {
      return VirtualDocumentCard(
        document: item.document!,
        onTap: onTap ?? () => _openCardItem(context, item),
        onFavoriteToggle: () {
          context.read<WalletDocumentProvider>().toggleDocumentFavorite(
            item.id,
          );
          context.read<WalletProvider>().loadWallet();
        },
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildStackedCardDeck(
    BuildContext context,
    List<StudioCardItem> cards,
  ) {
    if (_currentCardIndex >= cards.length) {
      _currentCardIndex = cards.length - 1;
    }
    if (_currentCardIndex < 0) {
      _currentCardIndex = 0;
    }

    final activeCard = cards[_currentCardIndex];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xs),

          // 1. Layered Stacked Cards presentation
          SizedBox(
            height: 295,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Visual Stack depth: Show up to 2 subsequent cards peeking underneath the top card
                for (int offset = 2; offset >= 1; offset--) ...[
                  if (_currentCardIndex + offset < cards.length)
                    Positioned(
                      top: 236.0 - (offset == 1 ? 22 : 0) + (offset * 16.0),
                      left: 28.0 + (offset * 8.0),
                      right: 28.0 + (offset * 8.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                        height: 54,
                        decoration: BoxDecoration(
                          color: _getPeekCardColor(
                            cards[_currentCardIndex + offset],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(50),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => _goToCard(
                              _currentCardIndex + offset,
                              cards.length,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      cards[_currentCardIndex + offset].title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    cards[_currentCardIndex + offset].category
                                        .replaceAll('_', ' ')
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(190),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 9.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],

                // Top Foreground Swipeable PageView (Seamless horizontal swipe to next card)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 245,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: cards.length,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() => _currentCardIndex = index);
                      HapticFeedback.selectionClick();
                    },
                    itemBuilder: (context, index) {
                      final card = cards[index];

                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          double pageOffset = 0.0;
                          if (_pageController.hasClients &&
                              _pageController.positions.length == 1 &&
                              _pageController.position.haveDimensions) {
                            pageOffset =
                                (_pageController.page ??
                                    _pageController.initialPage.toDouble()) -
                                index;
                          } else {
                            pageOffset = (_currentCardIndex - index).toDouble();
                          }

                          // Tactile Stack transformation: smooth scale, rotation, translation & opacity
                          final scale = (1.0 - (pageOffset.abs() * 0.08)).clamp(
                            0.86,
                            1.0,
                          );
                          final opacity = (1.0 - (pageOffset.abs() * 0.25))
                              .clamp(0.40, 1.0);
                          final translateY = pageOffset.abs() * 10.0;
                          final rotation = (pageOffset * -0.04).clamp(
                            -0.06,
                            0.06,
                          );

                          return Transform.translate(
                            offset: Offset(0, translateY),
                            child: Transform.rotate(
                              angle: rotation,
                              child: Transform.scale(
                                scale: scale,
                                child: Opacity(opacity: opacity, child: child),
                              ),
                            ),
                          );
                        },
                        child: Center(
                          child: _buildCardItemWidget(
                            card,
                            onTap: () => _openCardItem(context, card),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // 2. Stack Indicators & Controls (Card X of Y + Dots + Prev/Next buttons)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                  tooltip: 'Previous Card',
                  onPressed: _currentCardIndex > 0
                      ? () => _goToCard(_currentCardIndex - 1, cards.length)
                      : null,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Card ${_currentCardIndex + 1} of ${cards.length}',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextSecondary(context),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(cards.length, (dotIdx) {
                        final isActive = dotIdx == _currentCardIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          width: isActive ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primary
                                : AppColors.getTextSecondary(
                                    context,
                                  ).withAlpha(60),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  tooltip: 'Next Card',
                  onPressed: _currentCardIndex < cards.length - 1
                      ? () => _goToCard(_currentCardIndex + 1, cards.length)
                      : null,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // 3. Active Card Information Panel (Requirement 7)
          _buildActiveCardInfoPanel(context, activeCard),

          const SizedBox(height: AppSpacing.lg),

          // 4. Cards in Stack Tray (Tap to select card in stack)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Cards in Deck (${cards.length})',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextPrimary(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Swipe or tap to switch',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.getTextSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            itemCount: cards.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
            itemBuilder: (context, idx) {
              final cardItem = cards[idx];
              final isCurrent = idx == _currentCardIndex;

              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _goToCard(idx, cards.length),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.getPrimary(context).withAlpha(20)
                        : AppColors.getSurface(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCurrent
                              ? AppColors.getPrimary(context)
                              : Colors.transparent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cardItem.title,
                              style: TextStyle(
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isCurrent
                                    ? AppColors.getPrimary(context)
                                    : AppColors.getTextPrimary(context),
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              cardItem.subtitle,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.getTextSecondary(context),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (cardItem.isFavorite)
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 18,
                        ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right_rounded, size: 18),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  // ==========================================
  // ACTIVE CARD INFORMATION PANEL (Requirement 7)
  // ==========================================
  Widget _buildActiveCardInfoPanel(
    BuildContext context,
    StudioCardItem activeCard,
  ) {
    final isPayment =
        activeCard.type == StudioCardType.payment &&
        activeCard.paymentCard != null;
    final paymentCard = activeCard.paymentCard;
    final currentTheme = isPayment
        ? CardStudioTheme.getTheme(paymentCard!.themeGradient)
        : null;
    final currentLayout = isPayment
        ? CardStudioLayout.getLayout(paymentCard!.cardLayoutId)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Title, Category & Favorite Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activeCard.title,
                        style: AppTextStyles.getBodyLarge(
                          context,
                        ).copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activeCard.subtitle,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.getTextSecondary(context),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    activeCard.isFavorite
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: activeCard.isFavorite ? Colors.amber : null,
                    size: 24,
                  ),
                  tooltip: 'Toggle Favorite',
                  onPressed: () {
                    if (activeCard.type == StudioCardType.payment) {
                      context.read<WalletCardProvider>().toggleCardFavorite(
                        activeCard.id,
                      );
                    } else {
                      context
                          .read<WalletDocumentProvider>()
                          .toggleDocumentFavorite(activeCard.id);
                    }
                    context.read<WalletProvider>().loadWallet();
                  },
                ),
              ],
            ),

            // Theme & Layout Badges for Payment Cards
            if (isPayment && currentTheme != null && currentLayout != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  // Theme Selector Pill
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => CardThemeSheet.show(context, paymentCard!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: currentTheme.primaryAccent.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: currentTheme.primaryAccent,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            currentTheme.name,
                            style: TextStyle(
                              color: AppColors.getTextPrimary(context),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.palette_outlined,
                            size: 12,
                            color: currentTheme.primaryAccent,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Layout Selector Pill
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => CardLayoutSheet.show(context, paymentCard!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.getBackground(context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            currentLayout.icon,
                            size: 12,
                            color: AppColors.getTextSecondary(context),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            currentLayout.name,
                            style: TextStyle(
                              color: AppColors.getTextSecondary(context),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.expand_more, size: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const Divider(height: 20),

            // Actions Dock
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDeckActionButton(
                    context,
                    icon: Icons.info_outline_rounded,
                    label: 'Card Details',
                    onTap: () => _openCardItem(context, activeCard),
                  ),
                  const SizedBox(width: 8),
                  if (isPayment) ...[
                    _buildDeckActionButton(
                      context,
                      icon: Icons.palette_outlined,
                      label: 'Change Theme',
                      onTap: () => CardThemeSheet.show(context, paymentCard!),
                    ),
                    const SizedBox(width: 8),
                    _buildDeckActionButton(
                      context,
                      icon: Icons.view_quilt_outlined,
                      label: 'Change Layout',
                      onTap: () => CardLayoutSheet.show(context, paymentCard!),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _buildDeckActionButton(
                    context,
                    icon: _revealedCardId == activeCard.id
                        ? Icons.lock_open_rounded
                        : Icons.lock_outline_rounded,
                    label: _revealedCardId == activeCard.id
                        ? 'Hide Number'
                        : 'Secure Reveal',
                    color: _revealedCardId == activeCard.id
                        ? AppColors.primary
                        : null,
                    onTap: () {
                      if (_revealedCardId == activeCard.id) {
                        _remaskNumber();
                      } else {
                        _revealActiveCardNumber(activeCard);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildDeckActionButton(
                    context,
                    icon: Icons.copy_rounded,
                    label: 'Copy Number',
                    onTap: () => _copyActiveCardNumber(activeCard),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeckActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final effectiveColor = color ?? AppColors.getTextPrimary(context);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: effectiveColor, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: effectiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
