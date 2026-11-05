# -*- coding: utf-8 -*-
with open('lib/screens/wallet/card_detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

import_target = "import 'widgets/wallet_card_widget.dart';"
import_replacement = """import 'widgets/wallet_card_widget.dart';
import 'widgets/stitch_spotlight_card.dart';"""

if import_target in content and 'stitch_spotlight_card.dart' not in content:
    content = content.replace(import_target, import_replacement, 1)

card_target = """            // Card Presentation Widget with Biometric Reveal
            Center(
              child: WalletCardWidget(
                card: _currentCard,
                allowReveal: true,
                onTap: _showEditCardDialog,
              ),
            ),"""

card_replacement = """            // Authentic Spotlight Card Presentation (Exact Replica of Wallet Spotlight)
            Center(
              child: AspectRatio(
                aspectRatio: 1.586,
                child: StitchSpotlightCard.fromCard(
                  card: _currentCard,
                  onTap: _showEditCardDialog,
                ),
              ),
            ),"""

if card_target in content:
    content = content.replace(card_target, card_replacement, 1)
    with open('lib/screens/wallet/card_detail_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)
    print("Updated card_detail_screen.dart successfully!")
else:
    print("Target not found in card_detail_screen.dart!")

