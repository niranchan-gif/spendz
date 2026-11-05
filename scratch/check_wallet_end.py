with open('lib/screens/wallet/wallet_dashboard_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i in range(max(0, len(lines)-30), len(lines)):
    print(f"{i+1}: {repr(lines[i])}")

