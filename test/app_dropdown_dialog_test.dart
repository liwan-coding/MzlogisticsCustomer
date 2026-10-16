import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mz_logistics_customer_app/shared/widgets/app_dropdown.dart';

void main() {
  testWidgets('AppDropdown lays out inside an AlertDialog', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Payment'),
                        content: AppDropdown<String>(
                          label: 'Method',
                          value: 'cash',
                          options: const [
                            AppDropdownOption(value: 'cash', label: 'Cash'),
                            AppDropdownOption(value: 'card', label: 'Card'),
                          ],
                          onChanged: (_) {},
                        ),
                      );
                    },
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Method'), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);

    await tester.tap(find.text('Cash'));
    await tester.pumpAndSettle();

    expect(find.text('Card'), findsOneWidget);
  });
}
