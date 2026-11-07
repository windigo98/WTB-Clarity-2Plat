import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wtb_clarity/src/data/store.dart';
import 'package:wtb_clarity/src/logic/clarity_logic.dart';
import 'package:wtb_clarity/src/screens/games.dart';
import 'package:wtb_clarity/src/services/gateways.dart';
import 'package:wtb_clarity/src/state/app_state.dart';

const _length = 2;
const _seed = 4;

void main() {
  testWidgets('beacon relay stays dark through the entrance, then flashes in cadence', (tester) async {
    final sequence = makeSequence(_length, _seed);
    await _openBeacon(tester);

    expect(_litBeacon(tester), isNull, reason: 'the opening frame shows every beacon off');

    await tester.pump();
    final route = ModalRoute.of(tester.element(find.byType(BeaconBoard)))!;
    expect(route.animation!.status, isNot(AnimationStatus.completed));
    expect(
      _litBeacon(tester),
      isNull,
      reason: 'a color must not turn on while the route is still opening',
    );

    await _pumpUntilSettled(tester, route);
    expect(_litBeacon(tester), isNull, reason: 'the settled screen starts neutral');

    await tester.pump(const Duration(milliseconds: 699));
    expect(_litBeacon(tester), isNull, reason: 'the neutral pause lasts 700ms after the route settles');

    await tester.pump(const Duration(milliseconds: 1));
    expect(_litBeacon(tester), sequence.first);

    await tester.pump(const Duration(milliseconds: 520));
    expect(_litBeacon(tester), isNull);

    await tester.pump(const Duration(milliseconds: 180));
    expect(_litBeacon(tester), sequence[1]);
    await _drain(tester);
  });

  testWidgets('leaving during the beacon pause does not flash the next visit early', (tester) async {
    await _openBeacon(tester);
    await tester.pump();
    final route = ModalRoute.of(tester.element(find.byType(BeaconBoard)))!;
    await _pumpUntilSettled(tester, route);
    await tester.pump(const Duration(milliseconds: 200));
    expect(_litBeacon(tester), isNull);

    Navigator.of(tester.element(find.byType(BeaconBoard))).pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    expect(find.byType(BeaconBoard), findsNothing);

    await tester.tap(find.text('Open beacon'));
    await tester.pump();
    await tester.pump();
    final again = ModalRoute.of(tester.element(find.byType(BeaconBoard)))!;
    await _pumpUntilSettled(tester, again);
    await tester.pump(const Duration(milliseconds: 400));
    expect(_litBeacon(tester), isNull);
    expect(tester.takeException(), isNull);
    await _drain(tester);
  });
}

Future<void> _drain(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 5));
}

Future<void> _pumpUntilSettled(WidgetTester tester, ModalRoute<dynamic> route) async {
  var steps = 0;
  while (route.animation!.status != AnimationStatus.completed) {
    expect(_litBeacon(tester), isNull);
    await tester.pump(const Duration(milliseconds: 50));
    steps += 1;
    expect(steps, lessThan(40), reason: 'route transition did not finish');
  }
}

Future<void> _openBeacon(WidgetTester tester) async {
  final state = AppState(
    MemoryStore(),
    const PurchaseGateway(),
    const CrewGateway(),
    clock: () => DateTime(2026, 10, 13, 9),
  );
  await state.load();
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: state,
      child: const MaterialApp(home: _BeaconOpener()),
    ),
  );
  await tester.tap(find.text('Open beacon'));
  await tester.pump();
}

class _BeaconOpener extends StatelessWidget {
  const _BeaconOpener();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  body: BeaconBoard(
                    length: _length,
                    seed: _seed,
                    onFinished: (_) async {},
                  ),
                ),
              ),
            );
          },
          child: const Text('Open beacon'),
        ),
      ),
    );
  }
}

/// Index of a fully lit beacon, or null when every beacon is in the off state.
int? _litBeacon(WidgetTester tester) {
  final boxes = tester.widgetList<DecoratedBox>(
    find.descendant(of: find.byType(BeaconBoard), matching: find.byType(DecoratedBox)),
  );
  var index = 0;
  for (final box in boxes) {
    final decoration = box.decoration;
    if (decoration is BoxDecoration && (decoration.color?.a ?? 0) > 0.9) {
      return index;
    }
    index += 1;
  }
  return null;
}
