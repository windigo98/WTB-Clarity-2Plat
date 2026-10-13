import 'package:flutter/material.dart';

class ThemePreset {
  const ThemePreset({
    required this.id,
    required this.name,
    required this.seed,
    required this.foam,
    required this.ink,
    required this.dark,
  });

  final String id;
  final String name;
  final Color seed;
  final Color foam;
  final Color ink;
  final bool dark;
}

const themePresets = <ThemePreset>[
  ThemePreset(
    id: 'theme_tideglass',
    name: 'Tideglass',
    seed: Color(0xFF0F766E),
    foam: Color(0xFFFFF8EF),
    ink: Color(0xFF1C1917),
    dark: false,
  ),
  ThemePreset(
    id: 'theme_starwharf',
    name: 'Starwharf',
    seed: Color(0xFFE6B325),
    foam: Color(0xFF101820),
    ink: Color(0xFFF8F1DE),
    dark: true,
  ),
  ThemePreset(
    id: 'theme_emberkeep',
    name: 'Ember Keep',
    seed: Color(0xFFE85D4C),
    foam: Color(0xFF241614),
    ink: Color(0xFFFFF1EA),
    dark: true,
  ),
  ThemePreset(
    id: 'theme_moonlace',
    name: 'Moonlace',
    seed: Color(0xFF7C8CFF),
    foam: Color(0xFF1B1630),
    ink: Color(0xFFF4F0FF),
    dark: true,
  ),
];

ThemePreset presetFor(String id) {
  for (final preset in themePresets) {
    if (preset.id == id) return preset;
  }
  return themePresets.first;
}

class _RiseFade extends PageTransitionsBuilder {
  const _RiseFade();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}

ThemeData buildClarityTheme(String id) {
  final preset = presetFor(id);
  final scheme = ColorScheme.fromSeed(
    seedColor: preset.seed,
    brightness: preset.dark ? Brightness.dark : Brightness.light,
    primary: preset.dark ? preset.seed : const Color(0xFF0F766E),
  );
  const display = TextStyle(fontFamily: 'Cinzel', fontWeight: FontWeight.w700, height: 1.15);
  final ink = preset.dark ? preset.ink : const Color(0xFF1C1917);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Nunito',
    scaffoldBackgroundColor: Colors.transparent,
    splashFactory: InkSparkle.splashFactory,
    textTheme: TextTheme(
      displayMedium: display.copyWith(fontSize: 56, color: ink),
      displaySmall: display.copyWith(fontSize: 36, color: ink),
      headlineMedium: display.copyWith(fontSize: 28, color: ink),
      headlineSmall: display.copyWith(fontSize: 22, color: ink),
      titleLarge: display.copyWith(fontSize: 20, color: ink),
      titleMedium: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800, fontSize: 16),
      bodyMedium: TextStyle(fontFamily: 'Nunito', fontSize: 15, height: 1.35, color: ink),
      bodySmall: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: ink.withValues(alpha: 0.8)),
      labelLarge: const TextStyle(fontFamily: 'Cinzel', fontWeight: FontWeight.w700, fontSize: 14),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: preset.dark ? preset.ink : const Color(0xFFFFF8EF),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: display.copyWith(fontSize: 22, color: preset.dark ? preset.ink : const Color(0xFFFFF8EF)),
    ),
    cardTheme: CardThemeData(
      color: preset.dark ? const Color(0xF02A2438) : const Color(0xFFFFFBF5),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xF0162320),
      indicatorColor: const Color(0xFF1FA7A0),
      height: 68,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFFFFF6EA)),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? const Color(0xFFFFE7A3) : const Color(0xFFD7EDE8),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: const WidgetStatePropertyAll(Color(0xFF0F766E)),
        foregroundColor: const WidgetStatePropertyAll(Color(0xFFFFF8EF)),
        elevation: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.pressed) ? 1 : 8),
        shadowColor: const WidgetStatePropertyAll(Color(0x66064E3B)),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 22, vertical: 16)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontFamily: 'Cinzel', fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF134E4A),
        side: const BorderSide(color: Color(0xFF0F766E), width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontFamily: 'Cinzel', fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: Color(0xFF57534E), fontFamily: 'Nunito'),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE7D3B0))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFFFFF8EF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titleTextStyle: display.copyWith(fontSize: 22, color: ink),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _RiseFade(),
        TargetPlatform.iOS: _RiseFade(),
        TargetPlatform.macOS: _RiseFade(),
        TargetPlatform.linux: _RiseFade(),
        TargetPlatform.windows: _RiseFade(),
        TargetPlatform.fuchsia: _RiseFade(),
      },
    ),
  );
}

Color rarityColor(String name) => switch (name) {
  'Uncommon' => const Color(0xFF2F9E6B),
  'Rare' => const Color(0xFF3B82F6),
  'Epic' => const Color(0xFF9B5DE5),
  'Legendary' => const Color(0xFFE6A317),
  'Mythic' => const Color(0xFFFF4D8D),
  _ => const Color(0xFF8B95A7),
};

enum Scene { beach, tower, arcade, night }

String sceneAsset(Scene scene) => switch (scene) {
  Scene.beach => 'assets/art/bg_beach.jpg',
  Scene.tower => 'assets/art/bg_tower.jpg',
  Scene.arcade => 'assets/art/bg_arcade.jpg',
  Scene.night => 'assets/art/bg_night.jpg',
};

String? avatarAsset(String id) => switch (id) {
  'avatar_scout' => 'assets/art/avatar_scout.jpg',
  'avatar_emberfox' => 'assets/art/avatar_emberfox.jpg',
  'avatar_moonmoth' => 'assets/art/avatar_moonmoth.jpg',
  'avatar_kelpknight' => 'assets/art/avatar_kelpknight.jpg',
  'avatar_starwren' => 'assets/art/avatar_starwren.jpg',
  _ => null,
};

String? shopArt(String id) => switch (id) {
  'freeze' => 'assets/art/item_freeze.jpg',
  'life' => 'assets/art/item_life.jpg',
  'peek' || 'time' || 'hint' || 'shuffle' => 'assets/art/item_boosters.jpg',
  'card_constellation' => 'assets/art/card_constellation.jpg',
  'pouch_small' || 'chest_large' => 'assets/art/item_life.jpg',
  _ => avatarAsset(id),
};
