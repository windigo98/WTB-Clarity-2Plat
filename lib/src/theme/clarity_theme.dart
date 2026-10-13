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

ThemeData buildClarityTheme(String id) {
  final preset = presetFor(id);
  final scheme = ColorScheme.fromSeed(
    seedColor: preset.seed,
    brightness: preset.dark ? Brightness.dark : Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Nunito',
    scaffoldBackgroundColor: preset.foam,
    appBarTheme: AppBarTheme(
      backgroundColor: preset.foam,
      foregroundColor: preset.ink,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: preset.dark ? const Color(0xFF2A2438) : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: preset.dark ? const Color(0xFF16141F) : Colors.white,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 12),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
