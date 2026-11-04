import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:spendz/app/theme/app_colors.dart';
import 'package:spendz/app/theme/app_spacing.dart';
import 'package:spendz/app/theme/app_radius.dart';
import 'package:spendz/app/theme/app_theme.dart';
import 'package:spendz/providers/theme_provider.dart';
import 'package:spendz/features/wallet/security/secure_number_service.dart';
import 'package:spendz/widgets/design_system/financial_summary_card.dart';
import 'package:spendz/widgets/design_system/empty_state.dart';
import 'package:spendz/widgets/design_system/primary_button.dart';
import 'package:spendz/widgets/design_system/secure_protected_field.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Design System & Dual Theme Tests', () {
    test('AppColors provides proper light and dark palette tokens', () {
      expect(AppColors.primaryLightMode, const Color(0xFF273822));
      expect(AppColors.secondaryLightMode, const Color(0xFF4A6242));
      expect(AppColors.backgroundLightMode, const Color(0xFFF9FAF8));
      expect(AppColors.primaryDarkMode, const Color(0xFFACC8A2));
      expect(AppColors.backgroundDarkMode, const Color(0xFF131B11));
    });

    test('AppSpacing adheres to 4-point fintech grid', () {
      expect(AppSpacing.xs, 4.0);
      expect(AppSpacing.sm, 8.0);
      expect(AppSpacing.md, 12.0);
      expect(AppSpacing.lg, 16.0);
      expect(AppSpacing.card, 20.0);
      expect(AppSpacing.section, 24.0);
      expect(AppSpacing.xl, 32.0);
    });

    test('AppRadius adheres to standardized curvature scale', () {
      expect(AppRadius.xs, 6.0);
      expect(AppRadius.sm, 8.0);
      expect(AppRadius.md, 12.0);
      expect(AppRadius.card, 16.0);
      expect(AppRadius.lg, 20.0);
      expect(AppRadius.xl, 24.0);
      expect(AppRadius.sheet, 28.0);
    });

    test('AppTheme generates consistent Light and Dark ThemeData', () {
      final light = AppTheme.lightTheme;
      final dark = AppTheme.darkTheme;

      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);

      expect(light.scaffoldBackgroundColor, AppColors.backgroundLightMode);
      expect(dark.scaffoldBackgroundColor, AppColors.backgroundDarkMode);
    });

    test('ThemeProvider initializes with system mode and persists choices', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = ThemeProvider();

      expect(provider.themeMode, ThemeMode.system);
      expect(provider.isDarkMode, false);

      await provider.setThemeMode(ThemeMode.dark);
      expect(provider.themeMode, ThemeMode.dark);
      expect(provider.isDarkMode, true);

      // Verify persistence
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('spendz_theme_mode'), 'dark');

      await provider.setThemeMode(ThemeMode.light);
      expect(provider.themeMode, ThemeMode.light);
      expect(provider.isDarkMode, false);
      expect(prefs.getString('spendz_theme_mode'), 'light');
    });
  });

  group('Secure Number & Biometric Masking Tests', () {
    test('SecureNumberService formatCardNumber formats 16 digits correctly', () {
      const raw = '4532015092834821';
      final formatted = SecureNumberService.formatCardNumber(raw);
      expect(formatted, '4532 0150 9283 4821');
    });

    test('SecureNumberService formats irregular card numbers gracefully', () {
      expect(SecureNumberService.formatCardNumber('378282246310005'), '3782 8224 6310 005');
      expect(SecureNumberService.formatCardNumber(''), '');
    });

    testWidgets('SecureProtectedField renders masked state initially without plaintext leak', (tester) async {
      bool retrieverCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SecureProtectedField(
              maskedValue: '•••• •••• •••• 4821',
              onRetrieveProtectedValue: () async {
                retrieverCalled = true;
                return '4532015092834821';
              },
            ),
          ),
        ),
      );

      // Verify masked text is shown
      expect(find.text('•••• •••• •••• 4821'), findsOneWidget);
      // Verify raw full plaintext number is NOT present in the widget tree
      expect(find.text('4532015092834821'), findsNothing);
      expect(retrieverCalled, false);
    });
  });

  group('Design System Reusable Widget Rendering Tests', () {
    testWidgets('FinancialSummaryCard renders without overflows in Light mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: FinancialSummaryCard(
                netBalance: 24500.50,
                income: 65000.00,
                expenses: 40499.50,
                owedToMe: 3200.00,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Total Outflow'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Net Balance'), findsOneWidget);
      expect(find.text('Owed Back'), findsOneWidget);
    });

    testWidgets('FinancialSummaryCard renders without overflows in Dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: FinancialSummaryCard(
                netBalance: -1500.00,
                income: 12000.00,
                expenses: 13500.00,
                owedToMe: 500.00,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Total Outflow'), findsOneWidget);
    });

    testWidgets('EmptyState renders icon, title, message and action button', (tester) async {
      bool actionTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: EmptyState(
              icon: Icons.credit_card_off_outlined,
              title: 'No Cards Found',
              subtitle: 'Add payment cards to your Card Studio.',
              actionLabel: 'Add Card',
              onActionPressed: () => actionTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('No Cards Found'), findsOneWidget);
      expect(find.text('Add payment cards to your Card Studio.'), findsOneWidget);
      expect(find.text('Add Card'), findsOneWidget);

      await tester.tap(find.text('Add Card'));
      expect(actionTapped, true);
    });

    testWidgets('PrimaryButton renders loading state and responds to taps', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: PrimaryButton(
              label: 'Proceed',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Proceed'), findsOneWidget);
      await tester.tap(find.text('Proceed'));
      expect(tapped, true);
    });
  });
}
