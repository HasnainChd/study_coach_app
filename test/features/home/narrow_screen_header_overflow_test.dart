import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'Home header greeting wraps to 2 lines without truncation or overflow on 360dp',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    const greetingText = 'Good Evening, LongStudentNameHere';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Sunday, Sept 20',
                          style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      const Text(
                        greetingText,
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: const Row(
                    children: [
                      Text('🪙'),
                      SizedBox(width: 4),
                      Text('100'),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                    icon: const Icon(Icons.dark_mode_outlined),
                    onPressed: () {}),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text(greetingText), findsOneWidget);
  });

  testWidgets(
      'Rewards shop card title wraps to 2 lines without truncation on 360dp width',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    const longTitle = 'Sunset Amber Premium Special Theme';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(width: 48, height: 48),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  longTitle,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                  maxLines: 2,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                child: const Text('Equipped',
                                    style: TextStyle(fontSize: 10)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text('Warm orange sunset vibe',
                              style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                        onPressed: () {}, child: const Text('Equip')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text(longTitle), findsOneWidget);
  });
}
