# script to inspect sections of wallet_dashboard_screen.dart
with open('lib/screens/wallet/wallet_dashboard_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

print(f"Total lines: {len(lines)}")
for i, line in enumerate(lines):
    if "_buildCardsSection" in line:
        print(f"_buildCardsSection at line {i+1}")
    if "_buildOfficialCardsDirectory" in line:
        print(f"_buildOfficialCardsDirectory at line {i+1}")
    if "_buildDirectoryCardItem" in line:
        print(f"_buildDirectoryCardItem at line {i+1}")
    if "_buildPassesSection" in line:
        print(f"_buildPassesSection at line {i+1}")

