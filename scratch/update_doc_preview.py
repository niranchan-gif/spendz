# -*- coding: utf-8 -*-
with open('lib/screens/wallet/document_preview_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

import_target = "import 'widgets/virtual_document_card.dart';"
import_replacement = """import 'widgets/virtual_document_card.dart';
import 'widgets/stitch_spotlight_card.dart';"""

if import_target in content and 'stitch_spotlight_card.dart' not in content:
    content = content.replace(import_target, import_replacement, 1)

card_target = "              // 1. Virtual Document Card Presentation\n              VirtualDocumentCard(document: doc, showShadow: true),"
card_replacement = """              // 1. Authentic Spotlight Card Presentation (Exact Replica of Wallet Spotlight)
              AspectRatio(
                aspectRatio: 1.586,
                child: StitchSpotlightCard.fromDocument(document: doc),
              ),"""

if card_target in content:
    content = content.replace(card_target, card_replacement, 1)
    with open('lib/screens/wallet/document_preview_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)
    print("Updated document_preview_screen.dart successfully!")
else:
    print("Target not found in document_preview_screen.dart!")

