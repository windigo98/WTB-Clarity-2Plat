import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wtb_clarity/main.dart';
import 'package:wtb_clarity/src/data/store.dart';
import 'package:wtb_clarity/src/services/gateways.dart';
import 'package:wtb_clarity/src/state/app_state.dart';

void main() {
  testWidgets('today lists the first habit and checks it in', (tester) async {
    final state = AppState(
      MemoryStore(),
      const PurchaseGateway(),
      const CrewGateway(),
      clock: () => DateTime(2026, 10, 13, 9),
    );
    await state.load();
    state.finishOnboarding(name: 'Ada', habitName: 'Drink water', glyph: '💧');

    await tester.pumpWidget(ClarityApp(state: state));
    expect(find.text('Drink water'), findsOneWidget);
    await tester.tap(find.byKey(Key('check-${state.data.habits.single.id}')));
    await tester.pump();
    expect(state.data.habits.single.checkIns, isNotEmpty);
    expect(find.byIcon(Icons.check_circle), findsWidgets);
  });
}
