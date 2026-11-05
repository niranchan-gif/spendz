# -*- coding: utf-8 -*-
import sys

with open('lib/screens/wallet/wallet_dashboard_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update _buildCardsSection
old_cards_section_start = "  // ─── 2. ALL CARDS & VAULT COLLECTION (SEAMLESS SWIPE & REARRANGE) ─────────\n  Widget _buildCardsSection(\n    BuildContext context,\n    List<WalletCardModel> cards,\n    List<WalletDocumentModel> documents,\n  ) {"

old_cards_section_target_end = "    // Sort according to custom card order if set\n    if (_customCardOrder.isNotEmpty) {"

new_cards_section = """  // ─── 2. ALL CARDS & VAULT COLLECTION (SEAMLESS SWIPE & REARRANGE) ─────────
  Widget _buildCardsSection(
    BuildContext context,
    List<WalletCardModel> cards,
    List<WalletDocumentModel> documents,
  ) {
    WalletDocumentModel? findDoc(List<String> keywords) {
      for (final doc in documents) {
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

    final List<_CardDeckItem> deckItems = [
      _CardDeckItem(
        id: 'spotlight_aadhaar',
        title: aadhaarDoc?.documentName ?? 'Aadhaar Card',
        subtitle: aadhaarDoc != null
            ? (aadhaarDoc.holderName?.isNotEmpty == true ? aadhaarDoc.holderName! : 'UIDAI Government ID')
            : 'Tap to Add & Encrypt',
        icon: Icons.fingerprint_rounded,
        color: const Color(0xFFFF933E),
        widget: aadhaarDoc != null
            ? StitchSpotlightCard.fromDocument(
                document: aadhaarDoc,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DocumentPreviewScreen(document: aadhaarDoc),
                    ),
                  );
                },
              )
            : StitchSpotlightCard(
                cardType: StitchCardType.aadhaar,
                holderName: 'Tap to Add Aadhaar',
                maskedNumber: '•••• •••• ••••',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DocumentCreationScreen(preselectedCategory: 'aadhaar'),
                    ),
                  );
                },
              ),
      ),
      _CardDeckItem(
        id: 'spotlight_pan',
        title: panDoc?.documentName ?? 'PAN Card',
        subtitle: panDoc != null
            ? (panDoc.holderName?.isNotEmpty == true ? panDoc.holderName! : 'Income Tax Dept')
            : 'Tap to Add & Encrypt',
        icon: Icons.credit_card_rounded,
        color: const Color(0xFF2E6385),
        widget: panDoc != null
            ? StitchSpotlightCard.fromDocument(
                document: panDoc,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DocumentPreviewScreen(document: panDoc),
                    ),
                  );
                },
              )
            : StitchSpotlightCard(
                cardType: StitchCardType.pan,
                holderName: 'Tap to Add PAN Card',
                maskedNumber: '••••••••••',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DocumentCreationScreen(preselectedCategory: 'pan'),
                    ),
                  );
                },
              ),
      ),
      _CardDeckItem(
        id: 'spotlight_debit',
        title: debitCard?.nickname ?? 'Spendz Platinum Debit',
        subtitle: debitCard != null
            ? '${debitCard.issuerName} • ${debitCard.cardNetwork}'
            : 'Tap to Add Debit Card',
        icon: Icons.credit_card_rounded,
        color: const Color(0xFF263143),
        widget: debitCard != null
            ? StitchSpotlightCard.fromCard(
                card: debitCard,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CardDetailScreen(card: debitCard),
                    ),
                  );
                },
              )
            : StitchSpotlightCard(
                cardType: StitchCardType.debit,
                holderName: 'Tap to Add Debit Card',
                maskedNumber: '•••• •••• •••• ••••',
                issuer: 'Debit Card',
                expiry: 'MM/YY',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CardsScreen(openAddDialog: true),
                    ),
                  );
                },
              ),
      ),
      _CardDeckItem(
        id: 'spotlight_credit',
        title: creditCard?.nickname ?? 'World Elite Credit',
        subtitle: creditCard != null
            ? '${creditCard.issuerName} • ${creditCard.cardNetwork}'
            : 'Tap to Add Credit Card',
        icon: Icons.diamond_rounded,
        color: const Color(0xFFFF933E),
        widget: creditCard != null
            ? StitchSpotlightCard.fromCard(
                card: creditCard,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CardDetailScreen(card: creditCard),
                    ),
                  );
                },
              )
            : StitchSpotlightCard(
                cardType: StitchCardType.credit,
                holderName: 'Tap to Add Credit Card',
                maskedNumber: '•••• •••• •••• ••••',
                issuer: 'Credit Card',
                expiry: 'MM/YY',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CardsScreen(openAddDialog: true),
                    ),
                  );
                },
              ),
      ),
      _CardDeckItem(
        id: 'spotlight_mediclaim',
        title: insuranceDoc?.documentName ?? 'Star Health Mediclaim',
        subtitle: insuranceDoc != null
            ? (insuranceDoc.holderName?.isNotEmpty == true ? insuranceDoc.holderName! : 'Cashless Medi-Claim')
            : 'Tap to Add & Encrypt',
        icon: Icons.medical_services_rounded,
        color: const Color(0xFFBA1A1A),
        widget: insuranceDoc != null
            ? StitchSpotlightCard.fromDocument(
                document: insuranceDoc,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DocumentPreviewScreen(document: insuranceDoc),
                    ),
                  );
                },
              )
            : StitchSpotlightCard(
                cardType: StitchCardType.mediclaim,
                holderName: 'Tap to Add Health Insurance',
                policyNumber: '••••••••••••',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DocumentCreationScreen(preselectedCategory: 'insurance'),
                    ),
                  );
                },
              ),
      ),
      _CardDeckItem(
        id: 'spotlight_voter',
        title: voterDoc?.documentName ?? 'Voter ID (EPIC)',
        subtitle: voterDoc != null
            ? (voterDoc.holderName?.isNotEmpty == true ? voterDoc.holderName! : 'ECI Official')
            : 'Tap to Add & Encrypt',
        icon: Icons.how_to_vote_rounded,
        color: const Color(0xFF2E6385),
        widget: voterDoc != null
            ? StitchSpotlightCard.fromDocument(
                document: voterDoc,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DocumentPreviewScreen(document: voterDoc),
                    ),
                  );
                },
              )
            : StitchSpotlightCard(
                cardType: StitchCardType.voterId,
                holderName: 'Tap to Add Voter ID',
                epicNumber: '••••••••••',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DocumentCreationScreen(preselectedCategory: 'voter_id'),
                    ),
                  );
                },
              ),
      ),
      _CardDeckItem(
        id: 'spotlight_passport',
        title: passportDoc?.documentName ?? 'Indian Passport',
        subtitle: passportDoc != null
            ? (passportDoc.holderName?.isNotEmpty == true ? passportDoc.holderName! : 'Republic of India')
            : 'Tap to Add & Encrypt',
        icon: Icons.public_rounded,
        color: const Color(0xFF122238),
        widget: passportDoc != null
            ? StitchSpotlightCard.fromDocument(
                document: passportDoc,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DocumentPreviewScreen(document: passportDoc),
                    ),
                  );
                },
              )
            : StitchSpotlightCard(
                cardType: StitchCardType.passport,
                holderName: 'Tap to Add Passport',
                passportNumber: '••••••••',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DocumentCreationScreen(preselectedCategory: 'passport'),
                    ),
                  );
                },
              ),
      ),
    ];

    // Include any additional custom documents
    final matchedDocIds = {
      if (aadhaarDoc != null) aadhaarDoc.id,
      if (panDoc != null) panDoc.id,
      if (insuranceDoc != null) insuranceDoc.id,
      if (voterDoc != null) voterDoc.id,
      if (passportDoc != null) passportDoc.id,
    };
    for (final customDoc in documents) {
      if (!matchedDocIds.contains(customDoc.id)) {
        deckItems.add(
          _CardDeckItem(
            id: 'doc_${customDoc.id}',
            title: customDoc.documentName,
            subtitle: customDoc.holderName?.isNotEmpty == true ? customDoc.holderName! : customDoc.category.toUpperCase(),
            icon: Icons.description_rounded,
            color: const Color(0xFF2E6385),
            widget: StitchSpotlightCard.fromDocument(
              document: customDoc,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DocumentPreviewScreen(document: customDoc),
                  ),
                );
              },
            ),
          ),
        );
      }
    }

    // Include any additional custom cards
    final matchedCardIds = {
      if (debitCard != null) debitCard.id,
      if (creditCard != null) creditCard.id,
    };
    for (final customCard in cards) {
      if (!matchedCardIds.contains(customCard.id)) {
        deckItems.add(
          _CardDeckItem(
            id: 'card_${customCard.id}',
            title: customCard.nickname,
            subtitle: '${customCard.issuerName} • ${customCard.cardNetwork}',
            icon: Icons.credit_card_rounded,
            color: const Color(0xFF263143),
            widget: StitchSpotlightCard.fromCard(
              card: customCard,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CardDetailScreen(card: customCard),
                  ),
                );
              },
            ),
          ),
        );
      }
    }

"""

if old_cards_section_start in content and old_cards_section_target_end in content:
    idx1 = content.find(old_cards_section_start)
    idx2 = content.find(old_cards_section_target_end)
    content = content[:idx1] + new_cards_section + content[idx2:]
    print("Updated _buildCardsSection successfully!")
else:
    print("Could not find _buildCardsSection target boundaries!")
    sys.exit(1)

with open('lib/screens/wallet/wallet_dashboard_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

