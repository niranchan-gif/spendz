# -*- coding: utf-8 -*-
with open('lib/screens/wallet/card_detail_screen.dart', 'r', encoding='utf-8') as f:
    c = f.read()

c = c.replace("import 'widgets/wallet_card_widget.dart';\n", "")
c = c.replace("import 'widgets/wallet_card_widget.dart';\r\n", "")

with open('lib/screens/wallet/card_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(c)

with open('lib/screens/wallet/document_preview_screen.dart', 'r', encoding='utf-8') as f:
    d = f.read()

d = d.replace("import 'widgets/virtual_document_card.dart';\n", "")
d = d.replace("import 'widgets/virtual_document_card.dart';\r\n", "")

with open('lib/screens/wallet/document_preview_screen.dart', 'w', encoding='utf-8') as f:
    f.write(d)

print("Removed unused imports!")

