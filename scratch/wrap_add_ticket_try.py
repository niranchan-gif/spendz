# -*- coding: utf-8 -*-
with open('lib/screens/wallet/wallet_dashboard_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

target = """                            await context.read<WalletProvider>().addPass(newPass);
                            await context.read<WalletPassProvider>().loadPasses();
                            await context.read<WalletProvider>().loadWallet();
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Transit Ticket saved in Digital Passes!',
                                  ),
                                  backgroundColor: Color(0xFF047857),
                                ),
                              );
                            }"""

replacement = """                            try {
                              await context.read<WalletProvider>().addPass(newPass);
                              await context.read<WalletPassProvider>().loadPasses();
                              await context.read<WalletProvider>().loadWallet();
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Transit Ticket saved in Digital Passes!',
                                    ),
                                    backgroundColor: Color(0xFF047857),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to save ticket: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }"""

if target in content:
    content = content.replace(target, replacement, 1)
    with open('lib/screens/wallet/wallet_dashboard_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)
    print("Added try-catch to _showAddTransitTicketModal successfully!")
else:
    print("Target not found for transit ticket save!")

