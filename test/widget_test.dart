import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_coach_app/core/widgets/glass_card.dart';
import 'package:study_coach_app/core/widgets/gradient_background.dart';

void main() {
  testWidgets('GlassCard renders child content correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GlassCard(
            child: Text('Glass Card Test'),
          ),
        ),
      ),
    );

    expect(find.text('Glass Card Test'), findsOneWidget);
  });

  testWidgets('GradientBackground renders child content correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GradientBackground(
            child: Text('Gradient Background Test'),
          ),
        ),
      ),
    );

    expect(find.text('Gradient Background Test'), findsOneWidget);
  });
}
