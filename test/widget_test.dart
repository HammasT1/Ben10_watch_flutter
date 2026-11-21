import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ben10_flutter/data/aliens.dart';
import 'package:ben10_flutter/main.dart';
import 'package:ben10_flutter/screens/intro_screen.dart';
import 'package:ben10_flutter/services/watch_feedback.dart';

void main() {
  final dial = find.byKey(const Key('watch-dial'));

  String hudLabel(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('hud-label'))).data!;

  testWidgets('Omnitrix watch loads in idle state', (tester) async {
    await tester.pumpWidget(
      OmnitrixApp(feedback: SilentWatchFeedback(), showIntro: false),
    );

    expect(find.text('XLR8'), findsOneWidget);
    expect(find.text('TURN THE DIAL  •  TAP THE CORE'), findsOneWidget);
    expect(find.text('REVERT'), findsNothing);
  });

  testWidgets('tapping the core transforms, times out and recharges', (
    tester,
  ) async {
    await tester.pumpWidget(
      OmnitrixApp(feedback: SilentWatchFeedback(), showIntro: false),
    );

    await tester.tapAt(tester.getCenter(dial));
    await tester.pump();
    expect(find.text('TRANSFORMING'), findsOneWidget);

    // Past the flash peak: transformed view with countdown.
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('REVERT'), findsOneWidget);
    expect(find.text('XLR8'), findsOneWidget);

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
    expect(find.text('XLR8'), findsOneWidget);
  });

  testWidgets('revert returns to idle without recharging', (tester) async {
    await tester.pumpWidget(
      OmnitrixApp(feedback: SilentWatchFeedback(), showIntro: false),
    );

    await tester.tapAt(tester.getCenter(dial));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 800));

    await tester.tap(find.text('REVERT'));
    await tester.pump();
    expect(find.text('REVERT'), findsNothing);
    expect(find.textContaining('RECHARGING'), findsNothing);
    expect(find.text('XLR8'), findsOneWidget);
  });

  testWidgets('tapping off-core does not transform', (tester) async {
    await tester.pumpWidget(
      OmnitrixApp(feedback: SilentWatchFeedback(), showIntro: false),
    );

    final rect = tester.getRect(dial);
    await tester.tapAt(rect.topLeft + const Offset(10, 10));
    await tester.pump();
    expect(find.text('TRANSFORMING'), findsNothing);
  });

  group('dial physics', () {
    Offset rimPoint(WidgetTester tester) {
      final rect = tester.getRect(dial);
      return rect.center + Offset(rect.width * 0.4, 0);
    }

    Future<String> settle(WidgetTester tester) async {
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      return hudLabel(tester);
    }

    testWidgets('a flick coasts past several aliens then stops', (
      tester,
    ) async {
      await tester.pumpWidget(
        OmnitrixApp(feedback: SilentWatchFeedback(), showIntro: false),
      );

      await tester.flingFrom(rimPoint(tester), const Offset(0, 160), 2400);
      await tester.pump(const Duration(milliseconds: 100));
      final mid = hudLabel(tester);

      final rest = await settle(tester);
      expect(rest, isNot('XLR8'));
      expect(rest, isNot(mid), reason: 'dial should keep coasting');

      // Fully settled: more time changes nothing.
      expect(await settle(tester), rest);
    });

    testWidgets('a small slow drag snaps back to the same alien', (
      tester,
    ) async {
      await tester.pumpWidget(
        OmnitrixApp(feedback: SilentWatchFeedback(), showIntro: false),
      );

      final gesture = await tester.startGesture(rimPoint(tester));
      // Well under half a slot (~16 degrees), moved slowly.
      for (var i = 0; i < 4; i++) {
        await gesture.moveBy(const Offset(0, 4));
        await tester.pump(const Duration(milliseconds: 200));
      }
      await gesture.up();

      expect(await settle(tester), 'XLR8');
    });

    testWidgets('core tap is ignored while the dial is still spinning', (
      tester,
    ) async {
      await tester.pumpWidget(
        OmnitrixApp(feedback: SilentWatchFeedback(), showIntro: false),
      );

      await tester.flingFrom(rimPoint(tester), const Offset(0, 160), 2400);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(tester.getCenter(dial));
      await tester.pump();
      expect(find.text('TRANSFORMING'), findsNothing);

      await settle(tester);
      await tester.tapAt(tester.getCenter(dial));
      await tester.pump();
      expect(find.text('TRANSFORMING'), findsOneWidget);
    });
  });

  group('sound and haptics', () {
    Future<void> transform(WidgetTester tester) async {
      await tester.tapAt(tester.getCenter(dial));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 800));
    }

    testWidgets('full cycle fires events in order', (tester) async {
      final feedback = SilentWatchFeedback();
      await tester.pumpWidget(
        OmnitrixApp(feedback: feedback, showIntro: false),
      );

      await transform(tester);
      expect(feedback.played, [
        WatchEvent.transformStart,
        WatchEvent.transformed,
      ]);

      for (var i = 0; i < 160; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(
        feedback.played.where((e) => e == WatchEvent.timeoutWarning).length,
        3,
        reason: 'one beep for each of the last 3 seconds',
      );
      expect(feedback.played, contains(WatchEvent.timedOut));

      // Locked watch refuses the core.
      await tester.tapAt(tester.getCenter(dial));
      await tester.pump();
      expect(feedback.played.last, WatchEvent.denied);

      await tester.pump(const Duration(seconds: 8, milliseconds: 100));
      await tester.pump();
      expect(feedback.played.last, WatchEvent.rechargeReady);
    });

    testWidgets('revert plays the revert event', (tester) async {
      final feedback = SilentWatchFeedback();
      await tester.pumpWidget(
        OmnitrixApp(feedback: feedback, showIntro: false),
      );

      await transform(tester);
      await tester.tap(find.text('REVERT'));
      await tester.pump();
      expect(feedback.played.last, WatchEvent.reverted);
    });

    testWidgets('turning the dial ticks once per alien passed', (tester) async {
      final feedback = SilentWatchFeedback();
      await tester.pumpWidget(
        OmnitrixApp(feedback: feedback, showIntro: false),
      );

      final rect = tester.getRect(dial);
      await tester.flingFrom(
        rect.center + Offset(rect.width * 0.4, 0),
        const Offset(0, 160),
        2400,
      );
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(feedback.played, isNotEmpty);
      expect(feedback.played.every((e) => e == WatchEvent.dialTick), isTrue);
    });

    testWidgets('mute toggle flips the muted flag', (tester) async {
      final feedback = SilentWatchFeedback();
      await tester.pumpWidget(
        OmnitrixApp(feedback: feedback, showIntro: false),
      );

      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
      await tester.tap(find.byKey(const Key('mute-toggle')));
      await tester.pump();
      expect(feedback.muted, isTrue);
      expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
    });
  });

  group('alien info', () {
    testWidgets('alien data is complete and slots map to images', (
      tester,
    ) async {
      expect(aliens, hasLength(11));
      for (var i = 0; i < aliens.length; i++) {
        final alien = aliens[i];
        expect(alien.image, 'assets/images/${i + 1}.png');
        expect(alien.name, isNotEmpty);
        expect(alien.powers, isNotEmpty);
        for (final stat in alien.stats.asMap.values) {
          expect(stat, inInclusiveRange(1, 10));
        }
      }
      expect(aliens.map((a) => a.name).toSet(), hasLength(aliens.length));
    });

    testWidgets('info sheet opens on the selected alien', (tester) async {
      await tester.pumpWidget(
        OmnitrixApp(feedback: SilentWatchFeedback(), showIntro: false),
      );

      await tester.tap(find.byKey(const Key('alien-info')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining(aliens[0].species), findsOneWidget);
      for (final power in aliens[0].powers) {
        expect(find.text(power), findsOneWidget);
      }
      expect(find.text('STRENGTH'), findsOneWidget);
    });

    testWidgets('SET ON DIAL turns the dial to the swiped-to alien', (
      tester,
    ) async {
      await tester.pumpWidget(
        OmnitrixApp(feedback: SilentWatchFeedback(), showIntro: false),
      );

      await tester.tap(find.byKey(const Key('alien-info')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Swipe two cards forward.
      for (var i = 0; i < 2; i++) {
        await tester.fling(find.byType(PageView), const Offset(-300, 0), 1500);
        for (var f = 0; f < 10; f++) {
          await tester.pump(const Duration(milliseconds: 60));
        }
      }
      expect(find.textContaining(aliens[2].species), findsOneWidget);

      await tester.tap(find.byKey(const Key('select-alien')));
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(hudLabel(tester), aliens[2].name.toUpperCase());
    });

    testWidgets('transformed view shows the alien name', (tester) async {
      await tester.pumpWidget(
        OmnitrixApp(feedback: SilentWatchFeedback(), showIntro: false),
      );

      await tester.tapAt(tester.getCenter(dial));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 800));

      final name = tester.widget<Text>(
        find.byKey(const Key('transformed-name')),
      );
      expect(name.data, aliens[0].name.toUpperCase());
      expect(find.byKey(const Key('transformed-info')), findsOneWidget);
    });
  });

  group('3D intro', () {
    Widget intro() => MaterialApp(
      home: IntroScreen(
        model: const SizedBox(key: Key('fake-model')),
        next: (_) => const Scaffold(body: Text('WATCH SCREEN')),
      ),
    );

    testWidgets('shows the model and an activate button', (tester) async {
      await tester.pumpWidget(intro());

      expect(find.byKey(const Key('fake-model')), findsOneWidget);
      expect(find.text('ACTIVATE'), findsOneWidget);
      expect(find.text('WATCH SCREEN'), findsNothing);
    });

    testWidgets('activate transitions to the watch screen', (tester) async {
      await tester.pumpWidget(intro());

      await tester.tap(find.byKey(const Key('activate')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('WATCH SCREEN'), findsOneWidget);
      expect(find.text('ACTIVATE'), findsNothing);
    });

    testWidgets('intro model asset is bundled', (tester) async {
      final data = await rootBundle.load(IntroScreen.modelAsset);
      // glTF binary magic number.
      expect(String.fromCharCodes(data.buffer.asUint8List(0, 4)), 'glTF');
    });
  });
}
