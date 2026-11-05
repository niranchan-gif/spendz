# -*- coding: utf-8 -*-
with open('lib/screens/wallet/wallet_dashboard_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find the end of _buildCardsSection and the start of _showRearrangeCardsModal
cards_end_idx = -1
modal_start_idx = -1

for i, line in enumerate(lines):
    if "void _showRearrangeCardsModal(" in line:
        modal_start_idx = i
        break

for i in range(modal_start_idx - 1, -1, -1):
    if lines[i].strip() == '}':
        cards_end_idx = i
        # Keep searching upwards until we find the real end of _buildCardsSection
        # The line before the real end of _buildCardsSection is:
        # '    );'
        if lines[i-1].strip() == ');':
            cards_end_idx = i
            break

print(f"cards_end_idx: {cards_end_idx+1}, modal_start_idx: {modal_start_idx+1}")
print("Between lines:", [lines[x].strip() for x in range(cards_end_idx + 1, modal_start_idx)])

# Replace between cards_end_idx + 1 and modal_start_idx with just a newline
lines = lines[:cards_end_idx+1] + ['\n'] + lines[modal_start_idx:]

with open('lib/screens/wallet/wallet_dashboard_screen.dart', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("Fixed braces in wallet_dashboard_screen.dart successfully!")

