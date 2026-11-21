import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ben10_flutter/main.dart';

void main() {
  final dial = find.byKey(const Key('watch-dial'));

  testWidgets('Omnitrix watch loads in idle state', (tester) async {
    await tester.pumpWidget(const OmnitrixApp());

    expect(find.text('ALIEN 1'), findsOneWidget);
    expect(find.text('TURN THE DIAL  •  TAP THE CORE'), findsOneWidget);
    expect(find.text('REVERT'), findsNothing);
  });

  testWidgets('tapping the core transforms, times out and recharges', (
    tester,
  ) async {
    await tester.pumpWidget(const OmnitrixApp());

    await tester.tapAt(tester.getCenter(dial));
    await tester.pump();
    expect(find.text('TRANSFORMING'), findsOneWidget);

    // Past the flash peak: transformed view with countdown.
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('REVERT'), findsOneWidget);
    expect(find.text('ALIEN 1'), findsOneWidget);

    // Timeout -> recharging, dial locked.
    await tester.pump(const Duration(seconds: 15));
    await tester.pump();
    expect(find.text('REVERT'), findsNothing);
    expect(find.textContaining('RECHARGING'), findsOneWidget);

    await tester.tapAt(tester.getCenter(dial));
    await tester.pump();
    expect(find.text('TRANSFORMING'), findsNothing);

    // Recharge finishes -> back to idle.
    await tester.pump(const Duration(seconds: 8, milliseconds: 100));
    await tester.pump();
    expect(find.textContaining('RECHARGING'), findsNothing);
    expect(find.text('ALIEN 1'), findsOneWidget);
  });

  testWidgets('revert returns to idle without recharging', (tester) async {
    await tester.pumpWidget(const OmnitrixApp());

    await tester.tapAt(tester.getCenter(dial));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 800));

    await tester.tap(find.text('REVERT'));
    await tester.pump();
    expect(find.text('REVERT'), findsNothing);
    expect(find.textContaining('RECHARGING'), findsNothing);
    expect(find.text('ALIEN 1'), findsOneWidget);
  });

  testWidgets('tapping off-core does not transform', (tester) async {
    await tester.pumpWidget(const OmnitrixApp());

    final rect = tester.getRect(dial);
    await tester.tapAt(rect.topLeft + const Offset(10, 10));
    await tester.pump();
    expect(find.text('TRANSFORMING'), findsNothing);
  });
}
