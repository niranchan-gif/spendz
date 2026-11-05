with open('lib/screens/wallet/wallet_dashboard_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i in range(965, min(len(lines), 1020)):
    print(f"{i+1}: {repr(lines[i])}")

