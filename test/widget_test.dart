import 'package:betooth/app/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('app boots', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: BetoothApp(),
      ),
    );

    await tester.pump();
    expect(find.text('Betooth'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}