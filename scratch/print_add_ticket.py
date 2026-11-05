with open('lib/screens/wallet/wallet_dashboard_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "Save Transit Ticket" in line:
        start = max(0, i - 15)
        end = min(len(lines), i + 45)
        for j in range(start, end):
            # Print with ascii escaping to avoid cp1252 error
            print(f"{j+1}: {lines[j].rstrip().encode('ascii', 'replace').decode('ascii')}")
        break

