import 'package:flutter/material.dart';

class LeanEatColors {
  static const ink = Color(0xFF10231C);
  static const forest = Color(0xFF0F6B4B);
  static const mint = Color(0xFF50C58A);
  static const lime = Color(0xFFC8F06A);
  static const cream = Color(0xFFF7F8F2);
  static const sand = Color(0xFFECEFE4);
  static const danger = Color(0xFFB42318);

  // Semantic aliases used by screens across the app.
  static const primary = forest;
  static const background = cream;
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
        textStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: .3,
        ),
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

/// LeanIt's lightweight vector logo.
///
/// It is drawn at runtime instead of shipping a large raster image. The white
/// L represents the user/base; the lime rising stroke represents measurable
/// progress. It stays crisp as an app mark, toolbar mark or large welcome logo.
class LeanEatLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;

  const LeanEatLogo({
    super.key,
    this.size = 72,
    this.showWordmark = true,
  });

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
              colors: [Color(0xFF0B553C), LeanEatColors.forest],
            ),
            borderRadius: BorderRadius.circular(size * .27),
            boxShadow: const [
              BoxShadow(
                color: Color(0x220F6B4B),
                blurRadius: 20,
                offset: Offset(0, 9),
              ),
            ],
          ),
          child: CustomPaint(painter: _LeanItMarkPainter()),
        ),
        if (showWordmark) ...[
          const SizedBox(width: 14),
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontFamily: 'Arial',
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.2,
              ),
              children: [
                TextSpan(
                  text: 'Lean',
                  style: TextStyle(color: LeanEatColors.ink),
                ),
                TextSpan(
                  text: 'It',
                  style: TextStyle(color: LeanEatColors.forest),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _LeanItMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .105
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Strong L-shaped base.
    final base = Path()
      ..moveTo(size.width * .30, size.height * .23)
      ..lineTo(size.width * .30, size.height * .70)
      ..quadraticBezierTo(
        size.width * .30,
        size.height * .76,
        size.width * .37,
        size.height * .76,
      )
      ..lineTo(size.width * .55, size.height * .76);
    canvas.drawPath(base, white);

    // Progress stroke rising out of the L.
    final progress = Paint()
      ..color = LeanEatColors.lime
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final rise = Path()
      ..moveTo(size.width * .47, size.height * .65)
      ..lineTo(size.width * .62, size.height * .49)
      ..lineTo(size.width * .76, size.height * .31);
    canvas.drawPath(rise, progress);

    // Small arrow head keeps the mark readable at launcher-icon scale.
    final arrow = Path()
      ..moveTo(size.width * .64, size.height * .31)
      ..lineTo(size.width * .76, size.height * .31)
      ..lineTo(size.width * .76, size.height * .43);
    canvas.drawPath(arrow, progress);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
