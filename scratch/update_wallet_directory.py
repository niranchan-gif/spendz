# -*- coding: utf-8 -*-
with open('lib/screens/wallet/wallet_dashboard_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

start_marker = "  // ─── 4. OFFICIAL CARDS DIRECTORY matching Image 3 ───────────────────────────\n  Widget _buildOfficialCardsDirectory("
end_marker = "  // ─── 5. TRAVEL & TRANSIT PASSES SECTION matching Image 3 ────────────────────"

idx1 = content.find(start_marker)
idx2 = content.find(end_marker)

new_code = """  // ─── 4. OFFICIAL CARDS DIRECTORY matching Image 3 ───────────────────────────
  Widget _buildOfficialCardsDirectory(
    BuildContext context,
    List<WalletCardModel> cards,
    List<WalletDocumentModel> docs,
  ) {
    WalletDocumentModel? findDoc(List<String> keywords) {
      for (final doc in docs) {
        final cat = doc.category.toLowerCase();
        final name = doc.documentName.toLowerCase();
        for (final k in keywords) {
          if (cat.contains(k) || name.contains(k)) return doc;
        }
      }
      return null;
    }

    final aadhaarDoc = findDoc(['aadhaar']);
    final panDoc = findDoc(['pan']);
    final insuranceDoc = findDoc(['insur', 'medic', 'health']);
    final voterDoc = findDoc(['voter', 'epic']);
    final passportDoc = findDoc(['passport']);

    WalletCardModel? debitCard;
    WalletCardModel? creditCard;
    for (final c in cards) {
      final isCredit = c.cardType.toLowerCase().contains('credit') || c.nickname.toLowerCase().contains('credit');
      if (isCredit && creditCard == null) {
        creditCard = c;
      } else if (!isCredit && debitCard == null) {
        debitCard = c;
      }
    }
    debitCard ??= cards.isNotEmpty ? cards.first : null;
    if (creditCard == null && cards.length > 1) {
      creditCard = cards[1];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Official Cards Directory',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: SpendzColors.textPrimary(context),
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Tap to inspect',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: SpendzColors.textSecondary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Item 1: Aadhaar Card (Funky Peach Clay)
        _buildDirectoryCardItem(
          context: context,
          tileBg: const Color(0xFFFFF4EC),
          tileBorder: const Color(0xFFFFD4B8),
          icon: Icons.fingerprint_rounded,
          iconBg: SpendzColors.tangerine.withAlpha(25),
          iconColor: SpendzColors.tangerine,
          title: aadhaarDoc?.documentName ?? 'Aadhaar Card',
          badgeText: 'UIDAI',
          badgeBg: SpendzColors.sunshineYellow,
          badgeColor: const Color(0xFF735500),
          subtitle: aadhaarDoc != null
              ? 'ID: ${aadhaarDoc.maskedIdentifier != null && aadhaarDoc.maskedIdentifier!.isNotEmpty ? aadhaarDoc.maskedIdentifier : "•••• ••••"} • Biometric Locked'
              : 'Not linked • Tap to add',
          statusWidget: Icon(
            aadhaarDoc != null ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
            size: 18,
            color: SpendzColors.tangerine,
          ),
          onTap: () {
            if (aadhaarDoc != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DocumentPreviewScreen(document: aadhaarDoc),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DocumentCreationScreen(preselectedCategory: 'aadhaar'),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 10),

        // Item 2: PAN Card (Funky Ice Blue Clay)
        _buildDirectoryCardItem(
          context: context,
          tileBg: const Color(0xFFEDF6FF),
          tileBorder: const Color(0xFFBAE0FF),
          icon: Icons.badge_outlined,
          iconBg: SpendzColors.tertiarySky.withAlpha(25),
          iconColor: SpendzColors.tertiarySky,
          title: panDoc?.documentName ?? 'PAN Card',
          badgeText: 'Linked',
          badgeBg: SpendzColors.tertiarySky.withAlpha(40),
          badgeColor: SpendzColors.tertiarySky,
          subtitle: panDoc != null
              ? 'PAN: ${panDoc.maskedIdentifier != null && panDoc.maskedIdentifier!.isNotEmpty ? panDoc.maskedIdentifier : "••••••••••"} • Income Tax Dept'
              : 'Not linked • Tap to link',
          statusWidget: Icon(
            panDoc != null ? Icons.link_rounded : Icons.add_circle_outline_rounded,
            size: 18,
            color: SpendzColors.tertiarySky,
          ),
          onTap: () {
            if (panDoc != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DocumentPreviewScreen(document: panDoc),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DocumentCreationScreen(preselectedCategory: 'pan'),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 10),

        // Item 3: Spendz Platinum Debit (Funky Cool Slate Clay)
        _buildDirectoryCardItem(
          context: context,
          tileBg: const Color(0xFFE9EEF7),
          tileBorder: const Color(0xFFCAD5E8),
          icon: Icons.credit_card_rounded,
          iconBg: const Color(0xFF1E293B),
          iconColor: SpendzColors.sunshineYellow,
          title: debitCard?.nickname ?? 'Spendz Platinum Debit',
          badgeText: debitCard != null ? '${debitCard.issuerName} • ${debitCard.cardNetwork}' : 'RuPay Platinum',
          badgeBg: SpendzColors.surfaceContainerHigh(context),
          badgeColor: SpendzColors.textSecondary(context),
          subtitle: debitCard != null
              ? '${debitCard.maskedNumber.isNotEmpty ? debitCard.maskedNumber : "•••• " + debitCard.lastFour} • Tap & Pay Active'
              : 'Not added • Tap to add',
          statusWidget: debitCard != null
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: SpendzColors.tangerine,
                  ),
                )
              : const Icon(
                  Icons.add_circle_outline_rounded,
                  size: 18,
                  color: Color(0xFF1E293B),
                ),
          onTap: () {
            if (debitCard != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CardDetailScreen(card: debitCard),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CardsScreen(openAddDialog: true),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 10),

        // Item 4: World Elite Credit (Funky Sunshine Gold Clay)
        _buildDirectoryCardItem(
          context: context,
          tileBg: const Color(0xFFFFF9E6),
          tileBorder: const Color(0xFFFFE8A3),
          icon: Icons.diamond_outlined,
          iconBg: SpendzColors.sunshineYellow.withAlpha(35),
          iconColor: const Color(0xFF735500),
          title: creditCard?.nickname ?? 'World Elite Credit',
          badgeText: creditCard != null ? '${creditCard.issuerName} • ${creditCard.cardNetwork}' : 'Visa Infinite',
          badgeBg: SpendzColors.sunshineYellow,
          badgeColor: const Color(0xFF735500),
          subtitle: creditCard != null
              ? '${creditCard.maskedNumber.isNotEmpty ? creditCard.maskedNumber : "•••• " + creditCard.lastFour} • Active'
              : 'Not added • Tap to add',
          statusWidget: Icon(
            creditCard != null ? Icons.stars_rounded : Icons.add_circle_outline_rounded,
            size: 18,
            color: const Color(0xFFB45309),
          ),
          onTap: () {
            if (creditCard != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CardDetailScreen(card: creditCard),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CardsScreen(openAddDialog: true),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 10),

        // Item 5: Star Health Mediclaim (Funky Rose Coral Clay)
        _buildDirectoryCardItem(
          context: context,
          tileBg: const Color(0xFFFFF1F2),
          tileBorder: const Color(0xFFFFCCD2),
          icon: Icons.health_and_safety_rounded,
          iconBg: const Color(0xFFFEE2E2),
          iconColor: const Color(0xFFDC2626),
          title: insuranceDoc?.documentName ?? 'Star Health Mediclaim',
          badgeText: 'Coverage',
          badgeBg: const Color(0xFFFEE2E2),
          badgeColor: const Color(0xFFDC2626),
          subtitle: insuranceDoc != null
              ? 'Policy: ${insuranceDoc.maskedIdentifier != null && insuranceDoc.maskedIdentifier!.isNotEmpty ? insuranceDoc.maskedIdentifier : "Active"} • Cashless Medi-Claim'
              : 'Not added • Tap to add',
          statusWidget: Icon(
            insuranceDoc != null ? Icons.verified_rounded : Icons.add_circle_outline_rounded,
            size: 18,
            color: const Color(0xFFDC2626),
          ),
          onTap: () {
            if (insuranceDoc != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DocumentPreviewScreen(document: insuranceDoc),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DocumentCreationScreen(preselectedCategory: 'insurance'),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 10),

        // Item 6: Voter ID (EPIC) (Funky Periwinkle/Lavender Clay)
        _buildDirectoryCardItem(
          context: context,
          tileBg: const Color(0xFFF1F0FF),
          tileBorder: const Color(0xFFD6D1FF),
          icon: Icons.how_to_vote_outlined,
          iconBg: const Color(0xFFE0E7FF),
          iconColor: SpendzColors.tertiarySky,
          title: voterDoc?.documentName ?? 'Voter ID (EPIC)',
          badgeText: 'ECI Official',
          badgeBg: const Color(0xFFE0E7FF),
          badgeColor: const Color(0xFF4338CA),
          subtitle: voterDoc != null
              ? 'EPIC: ${voterDoc.maskedIdentifier != null && voterDoc.maskedIdentifier!.isNotEmpty ? voterDoc.maskedIdentifier : "Verified"} • ECI Official'
              : 'Not added • Tap to add',
          statusWidget: Icon(
            voterDoc != null ? Icons.how_to_vote_rounded : Icons.add_circle_outline_rounded,
            size: 18,
            color: const Color(0xFF4338CA),
          ),
          onTap: () {
            if (voterDoc != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DocumentPreviewScreen(document: voterDoc),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DocumentCreationScreen(preselectedCategory: 'voter_id'),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 10),

        // Item 7: Indian Passport (Funky Seafoam Mint Clay)
        _buildDirectoryCardItem(
          context: context,
          tileBg: const Color(0xFFEBF5F5),
          tileBorder: const Color(0xFFC2E4E4),
          icon: Icons.public_rounded,
          iconBg: const Color(0xFF0F172A),
          iconColor: SpendzColors.sunshineYellow,
          title: passportDoc?.documentName ?? 'Indian Passport',
          badgeText: 'Republic of India',
          badgeBg: SpendzColors.sunshineYellow,
          badgeColor: const Color(0xFF735500),
          subtitle: passportDoc != null
              ? '${passportDoc.maskedIdentifier != null && passportDoc.maskedIdentifier!.isNotEmpty ? passportDoc.maskedIdentifier : "Valid"} • Republic of India'
              : 'Not added • Tap to add',
          statusWidget: Icon(
            passportDoc != null ? Icons.public_rounded : Icons.add_circle_outline_rounded,
            size: 18,
            color: const Color(0xFF0D9488),
          ),
          onTap: () {
            if (passportDoc != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DocumentPreviewScreen(document: passportDoc),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DocumentCreationScreen(preselectedCategory: 'passport'),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildDirectoryCardItem({
    required BuildContext context,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String badgeText,
    required Color badgeBg,
    required Color badgeColor,
    required String subtitle,
    Widget? statusWidget,
    Color? tileBg,
    Color? tileBorder,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: tileBg ?? SpendzColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tileBorder ?? SpendzColors.border(context),
          width: 1.0,
        ),
        boxShadow: SpendzColors.clayDropShadow(context),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: SpendzColors.textPrimary(context),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: SpendzColors.textSecondary(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (statusWidget != null) statusWidget,
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: SpendzColors.textSecondary(context).withAlpha(120),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

"""

content = content[:idx1] + new_code + content[idx2:]

with open('lib/screens/wallet/wallet_dashboard_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated _buildOfficialCardsDirectory successfully!")

