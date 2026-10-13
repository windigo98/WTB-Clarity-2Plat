import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/data/hive_store.dart';
import 'src/screens/shell.dart';
import 'src/services/gateways.dart';
import 'src/state/app_state.dart';
import 'src/theme/clarity_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await HiveStore.open();
  final state = AppState(store, const PurchaseGateway(), const CrewGateway());
  await state.load();
  runApp(ClarityApp(state: state));
}

class ClarityApp extends StatelessWidget {
  const ClarityApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: state,
      child: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          return MaterialApp(
            title: 'WTB Clarity 2plat',
            debugShowCheckedModeBanner: false,
            theme: buildClarityTheme(state.data.profile.themeId),
            home: state.data.profile.onboarded ? const Shell() : const OnboardingPage(),
          );
        },
      ),
    );
  }
}
