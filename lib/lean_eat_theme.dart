import 'package:flutter/material.dart';

class LeanEatColors {
  static const ink = Color(0xFF10231C);
  static const forest = Color(0xFF0F6B4B);
  static const mint = Color(0xFF50C58A);
  static const lime = Color(0xFFC8F06A);
  static const cream = Color(0xFFF7F8F2);
  static const sand = Color(0xFFECEFE4);
  static const danger = Color(0xFFB42318);
}

ThemeData leanEatTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: LeanEatColors.forest,
    brightness: Brightness.light,
    primary: LeanEatColors.forest,
    secondary: LeanEatColors.mint,
    surface: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: LeanEatColors.cream,
    fontFamily: 'Arial',
    appBarTheme: const AppBarTheme(
      backgroundColor: LeanEatColors.cream,
      foregroundColor: LeanEatColors.ink,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFDCE5DD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: LeanEatColors.forest, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: LeanEatColors.forest,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: .3),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFDCE5DD)),
      ),
    ),
  );
}

class LeanEatLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  const LeanEatLogo({super.key, this.size = 72, this.showWordmark = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [LeanEatColors.forest, LeanEatColors.mint],
            ),
            borderRadius: BorderRadius.circular(size * .28),
            boxShadow: const [
              BoxShadow(color: Color(0x220F6B4B), blurRadius: 22, offset: Offset(0, 10)),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.eco_rounded, color: LeanEatColors.lime, size: size * .55),
              Positioned(
                right: size * .14,
                bottom: size * .12,
                child: Icon(Icons.fitness_center_rounded, color: Colors.white, size: size * .28),
              ),
            ],
          ),
        ),
        if (showWordmark) ...[
          const SizedBox(width: 14),
          const Text(
            'LeanEat',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
              color: LeanEatColors.ink,
            ),
          ),
        ],
      ],
    );
  }
}
