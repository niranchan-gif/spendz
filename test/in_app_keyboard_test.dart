import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keybz/widgets/app_keyboard/app_keyboard.dart';

void main() {
  testWidgets('Keybz opens and types inside the app', (tester) async {
    final textController = TextEditingController();
    final keyboard = AppKeyboardController.instance;
    keyboard.hide();

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            AppKeyboardOverlay(child: child ?? const SizedBox.shrink()),
        home: Scaffold(
          body: AppTextFormField(
            controller: textController,
            hintText: 'Description',
          ),
        ),
      ),
    );

    await tester.tap(find.byType(AppTextFormField));
    await tester.pumpAndSettle();

    expect(find.byType(AppKeyboardView), findsOneWidget);
    expect(keyboard.isVisible, isTrue);

    keyboard.insertText('a');
    expect(textController.text, 'a');

    keyboard.hide();
    await tester.pumpAndSettle();
    textController.dispose();
  });
}
