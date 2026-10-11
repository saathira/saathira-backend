import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saathira/main.dart';

void main() {
  testWidgets('Signed-out user lands on welcome', (tester) async {
    // firebaseReadyProvider defaults to false → session resolves to null.
    await tester.pumpWidget(const ProviderScope(child: SaathiraApp()));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Get Started with Mobile Number'), findsOneWidget);
  });
}
