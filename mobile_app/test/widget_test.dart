import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:mobile_app/features/auth/presentation/pages/onboarding_screen.dart';

void main() {
  testWidgets('StreetWatch onboarding smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
    await tester.pumpAndSettle();

    expect(find.text('StreetWatch'), findsOneWidget);
    expect(find.text('Spot & Report'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });
}
