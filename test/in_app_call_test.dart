import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saathira/features/chat/in_app_call_screen.dart';

void main() {
  testWidgets('InAppCallScreen displays caller info, masked number shield, and handles controls', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: InAppCallScreen(
          recipientName: 'Priya Sharma',
          bookingId: 'test-booking-123',
          roleLabel: 'Verified Companion',
        ),
      ),
    );

    // Initial connecting state
    expect(find.text('Priya Sharma'), findsOneWidget);
    expect(find.text('Verified Companion'), findsOneWidget);
    expect(find.text('🔒 Number Masked • Encrypted Private Call'), findsOneWidget);
    expect(find.text('Securing private connection...'), findsOneWidget);

    // Progress to Ringing state
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('Ringing...'), findsOneWidget);

    // Progress to Connected state
    await tester.pump(const Duration(milliseconds: 2500));
    expect(find.text('00:00'), findsOneWidget);

    // Advance 3 seconds
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('00:03'), findsOneWidget);

    // Test mute toggle
    expect(find.text('Mute'), findsOneWidget);
    await tester.tap(find.text('Mute'));
    await tester.pump();
    expect(find.text('Unmute'), findsOneWidget);

    // Test speaker toggle
    expect(find.text('Speaker'), findsOneWidget);
    await tester.tap(find.text('Speaker'));
    await tester.pump();
    expect(find.text('Earpiece'), findsOneWidget);

    // End call
    await tester.tap(find.byIcon(Icons.call_end_rounded));
    await tester.pump();
    expect(find.text('Call Ended'), findsOneWidget);
  });
}
