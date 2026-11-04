import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../../features/wallet/security/secure_number_service.dart';
import '../../features/wallet/security/wallet_key_service.dart';
import '../../models/wallet_card_model.dart';
import '../../providers/wallet_card_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/design_system/empty_state.dart';
import '../../widgets/design_system/primary_button.dart';
import 'card_detail_screen.dart';
import 'widgets/wallet_card_widget.dart';

class CardsScreen extends StatefulWidget {
  final bool openAddDialog;

  const CardsScreen({super.key, this.openAddDialog = false});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  String _selectedFilter = 'all';
  final SecureNumberService _secureNumberService = SecureNumberService();
  late PageController _pageController;
  int _currentCardIndex = 0;
  bool _isStackedDeckView = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    if (widget.openAddDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddCardDialog(context);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
    String themeGradient = 'emerald';

    final themes = ['emerald', 'midnight', 'obsidian', 'amethyst', 'crimson', 'amber'];
    final cardTypes = ['credit', 'debit', 'atm', 'membership', 'loyalty', 'custom'];
    final networks = ['visa', 'mastercard', 'rupay', 'amex'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getSurface(context),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.roundedSheet,
      ),
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
                            style: AppTextStyles.getHeading2(context).copyWith(fontWeight: FontWeight.w700),
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
                          border: Border.all(color: AppColors.getPrimary(context).withAlpha(35)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.shield_outlined, color: AppColors.getPrimary(context), size: 18),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Spendz never stores CVVs or PINs. Stored full numbers are AES-256-GCM encrypted and revealed only via biometrics.',
                                style: AppTextStyles.getBodySmall(context).copyWith(fontSize: 11),
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
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: issuerController,
                              decoration: const InputDecoration(
                                labelText: 'Bank / Issuer (e.g. HDFC)',
                                prefixIcon: Icon(Icons.account_balance_outlined, size: 18),
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: cardType,
                              decoration: const InputDecoration(labelText: 'Card Type'),
                              items: cardTypes.map((t) {
                                return DropdownMenuItem(value: t, child: Text(t.toUpperCase()));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setModalState(() => cardType = val);
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
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
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
                                if (v == null || v.length != 4) return 'Enter 4 digits';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: cardNetwork,
                              decoration: const InputDecoration(labelText: 'Network'),
                              items: networks.map((net) {
                                return DropdownMenuItem(value: net, child: Text(net.toUpperCase()));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setModalState(() => cardNetwork = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: fullNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Full Card Number (Encrypted Hardware Storage)',
                          hintText: 'Optional — for biometric tap reveal',
                          prefixIcon: Icon(Icons.lock_outline_rounded, size: 18),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: expiryMonth,
                              decoration: const InputDecoration(labelText: 'Exp Month'),
                              items: List.generate(12, (i) => i + 1).map((m) {
                                return DropdownMenuItem(value: m, child: Text(m.toString().padLeft(2, '0')));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setModalState(() => expiryMonth = val);
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: expiryYear,
                              decoration: const InputDecoration(labelText: 'Exp Year'),
                              items: List.generate(15, (i) => 24 + i).map((y) {
                                return DropdownMenuItem(value: y, child: Text('20$y'));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setModalState(() => expiryYear = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text('Card Theme', style: AppTextStyles.labelMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 8,
                        children: themes.map((th) {
                          final isSelected = themeGradient == th;
                          return ChoiceChip(
                            label: Text(th.toUpperCase()),
                            selected: isSelected,
                            onSelected: (_) => setModalState(() => themeGradient = th),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      PrimaryButton(
                        label: 'Save Card to Wallet',
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            final cardProvider = context.read<WalletCardProvider>();
                            final walletProvider = context.read<WalletProvider>();
                            final messenger = ScaffoldMessenger.of(context);

                            final last4 = lastFourController.text.trim();
                            final cardId = const Uuid().v4();

                            final rawFull = fullNumberController.text.trim();
                            if (rawFull.isNotEmpty) {
                              try {
                                await _secureNumberService.saveCardFullNumber(cardId, rawFull);
                              } catch (_) {
                                try {
                                  final keyService = WalletKeyService();
                                  await keyService.resetAndRegenerateMasterKey();
                                  await _secureNumberService.saveCardFullNumber(cardId, rawFull);
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

  void _openCardDetail(BuildContext context, WalletCardModel card) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CardDetailScreen(card: card),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        title: Text('Card Studio', style: AppTextStyles.getHeading2(context)),
        actions: [
          IconButton(
            icon: Icon(
              _isStackedDeckView ? Icons.view_agenda_outlined : Icons.style_rounded,
              color: AppColors.getTextSecondary(context),
            ),
            tooltip: _isStackedDeckView ? 'Switch to List View' : 'Switch to Stacked Deck',
            onPressed: () => setState(() => _isStackedDeckView = !_isStackedDeckView),
          ),
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: AppColors.getPrimary(context)),
            tooltip: 'Add Card',
            onPressed: () => _showAddCardDialog(context),
          ),
        ],
      ),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, child) {
          final allCards = wallet.cards;
          final filteredCards = _selectedFilter == 'all'
              ? allCards
              : (_selectedFilter == 'favorite'
                  ? allCards.where((c) => c.isFavorite).toList()
                  : allCards.where((c) => c.cardType.toLowerCase() == _selectedFilter).toList());

          return Column(
            children: [
              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    _buildFilterChip('all', 'All Cards (${allCards.length})'),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('favorite', 'Favorites'),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('credit', 'Credit'),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('debit', 'Debit'),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('loyalty', 'Loyalty'),
                  ],
                ),
              ),

              // Cards Display: Stacked Swipeable Deck vs Classic List
              Expanded(
                child: filteredCards.isEmpty
                    ? EmptyState(
                        icon: Icons.credit_card_off_rounded,
                        title: 'No Cards in Studio',
                        message: 'Add debit, credit, or membership cards for organized tracking.',
                        actionLabel: 'Add Your First Card',
                        onAction: () => _showAddCardDialog(context),
                      )
                    : (_isStackedDeckView
                        ? _buildStackedCardDeck(context, filteredCards)
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                            itemCount: filteredCards.length,
                            itemBuilder: (context, index) {
                              final card = filteredCards[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                child: Center(
                                  child: WalletCardWidget(
                                    card: card,
                                    onTap: () => _openCardDetail(context, card),
                                    onFavoriteToggle: () {
                                      context.read<WalletCardProvider>().toggleCardFavorite(card.id);
                                      context.read<WalletProvider>().loadWallet();
                                    },
                                  ),
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

  Widget _buildStackedCardDeck(BuildContext context, List<WalletCardModel> cards) {
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
          const SizedBox(height: AppSpacing.sm),

          // 1. Stacked Swipeable PageView (Seamless swipe to next card)
          SizedBox(
            height: 240,
            child: PageView.builder(
              controller: _pageController,
              itemCount: cards.length,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentCardIndex = index);
              },
              itemBuilder: (context, index) {
                final card = cards[index];

                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double pageOffset = 0.0;
                    if (_pageController.position.haveDimensions) {
                      pageOffset = (_pageController.page ?? _pageController.initialPage.toDouble()) - index;
                    } else {
                      pageOffset = (_currentCardIndex - index).toDouble();
                    }

                    // Tactile Stack transformation: smooth scale, depth offset & opacity
                    final scale = (1.0 - (pageOffset.abs() * 0.08)).clamp(0.88, 1.0);
                    final opacity = (1.0 - (pageOffset.abs() * 0.25)).clamp(0.4, 1.0);
                    final translateY = pageOffset.abs() * 10.0;

                    return Transform.translate(
                      offset: Offset(0, translateY),
                      child: Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: Center(
                    child: WalletCardWidget(
                      card: card,
                      allowReveal: true,
                      onTap: () => _openCardDetail(context, card),
                      onFavoriteToggle: () {
                        context.read<WalletCardProvider>().toggleCardFavorite(card.id);
                        context.read<WalletProvider>().loadWallet();
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // 2. Stack Indicators & Page Counter ("Card X of Y")
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary
                          : AppColors.getTextSecondary(context).withAlpha(60),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // 3. Quick Action Dock for the Active Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.getBorder(context)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDeckActionButton(
                    context,
                    icon: Icons.info_outline_rounded,
                    label: 'Card Details',
                    onTap: () => _openCardDetail(context, activeCard),
                  ),
                  _buildDeckActionButton(
                    context,
                    icon: activeCard.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                    label: activeCard.isFavorite ? 'Favorited' : 'Favorite',
                    color: activeCard.isFavorite ? Colors.amber : null,
                    onTap: () {
                      context.read<WalletCardProvider>().toggleCardFavorite(activeCard.id);
                      context.read<WalletProvider>().loadWallet();
                    },
                  ),
                  _buildDeckActionButton(
                    context,
                    icon: Icons.copy_rounded,
                    label: 'Copy Number',
                    onTap: () async {
                      final fullNum = await _secureNumberService.getCardFullNumber(activeCard.id);
                      final numToCopy = fullNum ?? activeCard.lastFour;
                      await Clipboard.setData(ClipboardData(text: numToCopy));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Card number copied: $numToCopy'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // 4. Studio Cards Stack Tray (Tap to select card in stack)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cards in Deck (${cards.length})',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
                Text(
                  'Swipe to switch',
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
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            itemCount: cards.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
            itemBuilder: (context, idx) {
              final cardItem = cards[idx];
              final isCurrent = idx == _currentCardIndex;

              return InkWell(
                onTap: () {
                  setState(() => _currentCardIndex = idx);
                  _pageController.animateToPage(
                    idx,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                  );
                },
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.primary.withAlpha(20)
                        : AppColors.getSurface(context),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isCurrent
                          ? AppColors.primary
                          : AppColors.getBorder(context),
                      width: isCurrent ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: isCurrent ? AppColors.primary : AppColors.getTextSecondary(context).withAlpha(40),
                        ),
                        child: Center(
                          child: Text(
                            cardItem.cardNetwork.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cardItem.nickname,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.getTextPrimary(context),
                              ),
                            ),
                            Text(
                              '•••• ${cardItem.lastFour} • ${cardItem.issuerName}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.getTextSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: AppColors.getTextSecondary(context),
                        ),
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

  Widget _buildDeckActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final textColor = AppColors.getTextPrimary(context);
    final iconColor = color ?? AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = key),
      selectedColor: AppColors.getPrimary(context).withAlpha(30),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppColors.getPrimary(context) : AppColors.getTextSecondary(context),
      ),
    );
  }
}
