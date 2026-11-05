# -*- coding: utf-8 -*-
with open('lib/screens/wallet/wallet_dashboard_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace preselectedCategory with initialCategory
content = content.replace("preselectedCategory:", "initialCategory:")

# Replace CardDetailScreen(card: debitCard) with CardDetailScreen(card: debitCard!)
content = content.replace("CardDetailScreen(card: debitCard)", "CardDetailScreen(card: debitCard!)")

# Replace CardDetailScreen(card: creditCard) with CardDetailScreen(card: creditCard!)
content = content.replace("CardDetailScreen(card: creditCard)", "CardDetailScreen(card: creditCard!)")

with open('lib/screens/wallet/wallet_dashboard_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed parameters in wallet_dashboard_screen.dart!")

