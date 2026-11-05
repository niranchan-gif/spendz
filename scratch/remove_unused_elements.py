# -*- coding: utf-8 -*-
with open('lib/screens/wallet/wallet_dashboard_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

import re

# Remove _getCategoryIcon and _getCategoryColor
# Remove _buildHardwareEncryptedFooter
content = re.sub(r'  IconData _getCategoryIcon\([^)]*\)\s*\{[^}]*\}', '', content)
content = re.sub(r'  Color _getCategoryColor\([^)]*\)\s*\{[^}]*\}', '', content)
content = re.sub(r'  // ─── 6\. 256-BIT HARDWARE ENCRYPTED FOOTER TRUST BADGE ───────────────────────\s*Widget _buildHardwareEncryptedFooter\(BuildContext context\)\s*\{[\s\S]*?^\s*\}', '', content, flags=re.MULTILINE)

with open('lib/screens/wallet/wallet_dashboard_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Cleaned up unused elements!")

