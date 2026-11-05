# -*- coding: utf-8 -*-
with open('lib/screens/transactions/imported_transactions_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("importProvider.rejectTransaction(tx.reference)", "importProvider.removeTransaction(tx)")

with open('lib/screens/transactions/imported_transactions_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed imported_transactions_screen.dart!")

