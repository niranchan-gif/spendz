with open('lib/screens/wallet/wallet_dashboard_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

start_marker = "  // ─── 4. OFFICIAL CARDS DIRECTORY matching Image 3 ───────────────────────────\n  Widget _buildOfficialCardsDirectory("
end_marker = "  // ─── 5. TRAVEL & TRANSIT PASSES SECTION matching Image 3 ────────────────────"

print("Start marker in content:", start_marker in content)
print("End marker in content:", end_marker in content)

