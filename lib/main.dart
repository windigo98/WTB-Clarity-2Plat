import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/data/hive_store.dart';
import 'src/screens/shell.dart';
import 'src/services/gateways.dart';
import 'src/state/app_state.dart';
import 'src/theme/clarity_theme.dart';
import 'src/widgets/chrome.dart';

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
            home: const SplashGate(),
          );
        },
      ),
    );
  }
}

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  var _ready = false;

  @override
  void initState() {
    super.initState();
    final testing = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (testing) {
      _ready = true;
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final onboarded = context.watch<AppState>().data.profile.onboarded;
    if (!_ready) {
      return const SceneBackdrop(
        scene: Scene.night,
        child: Center(child: WingsCrewLogo(height: 140)),
      );
    }
    return onboarded ? const Shell() : const OnboardingPage();
  }
}
