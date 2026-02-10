import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bang/main.dart';

void main() {
  testWidgets('Prayer app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => AppProvider(),
        child: const PrayerTimesApp(),
      ),
    );

    // Verify that the app builds without errors
    expect(find.byType(PrayerTimesApp), findsOneWidget);
  });
}