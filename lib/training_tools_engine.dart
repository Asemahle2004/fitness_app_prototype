import 'dart:math' as math;

import 'training_settings.dart';

class PlateLoadResult {
  final double targetTotal;
  final double barWeight;
  final List<double> platesPerSide;
  final double achievedTotal;

  const PlateLoadResult({
    required this.targetTotal,
    required this.barWeight,
    required this.platesPerSide,
    required this.achievedTotal,
  });

  double get difference => achievedTotal - targetTotal;
}

class TrainingToolsEngine {
  static const double poundsPerKg = 2.2046226218;
  static const double milesPerKm = 0.6213711922;
  static const double kmPerMile = 1.609344;
  static const double inchesPerCm = 0.3937007874;

  static double kgToLb(double kg) => kg * poundsPerKg;
  static double lbToKg(double lb) => lb / poundsPerKg;
  static double kmToMiles(double km) => km * milesPerKm;
  static double milesToKm(double miles) => miles * kmPerMile;
  static double cmToInches(double cm) => cm * inchesPerCm;
  static double inchesToCm(double inches) => inches / inchesPerCm;

  static double toCanonicalWeight(double value, UnitSystem system) =>
      system == UnitSystem.metric ? value : lbToKg(value);

  static double fromCanonicalWeight(double kg, UnitSystem system) =>
      system == UnitSystem.metric ? kg : kgToLb(kg);

  static double toCanonicalDistanceKm(double value, UnitSystem system) =>
      system == UnitSystem.metric ? value : milesToKm(value);

  static double fromCanonicalDistanceKm(double km, UnitSystem system) =>
      system == UnitSystem.metric ? km : kmToMiles(km);

  static double paceForDisplay(double secondsPerKm, UnitSystem system) =>
      system == UnitSystem.metric ? secondsPerKm : secondsPerKm * kmPerMile;

  static String formatPace(double? secondsPerKm, UnitSystem system) {
    if (secondsPerKm == null || !secondsPerKm.isFinite || secondsPerKm <= 0) {
      return system == UnitSystem.metric ? '--:-- /km' : '--:-- /mi';
    }
    final total = paceForDisplay(secondsPerKm, system).round();
    final minutes = total ~/ 60;
    final seconds = total % 60;
    final suffix = system == UnitSystem.metric ? '/km' : '/mi';
    return '$minutes:${seconds.toString().padLeft(2, '0')} $suffix';
  }

  static String formatDistanceMeters(double meters, UnitSystem system) {
    final km = meters / 1000;
    final value = fromCanonicalDistanceKm(km, system);
    final unit = system == UnitSystem.metric ? 'km' : 'mi';
    return '${value.toStringAsFixed(2)} $unit';
  }

  static String formatWeight(double kg, UnitSystem system, {int decimals = 1}) {
    final value = fromCanonicalWeight(kg, system);
    final unit = system == UnitSystem.metric ? 'kg' : 'lb';
    final text = value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(decimals);
    return '$text $unit';
  }

  /// Epley estimate, capped to a practical 1–15 rep input range.
  static double estimatedOneRepMaxKg({
    required double weightKg,
    required int reps,
  }) {
    if (weightKg <= 0 || reps <= 0) return 0;
    if (reps == 1) return weightKg;
    final safeReps = reps.clamp(1, 15);
    return weightKg * (1 + safeReps / 30);
  }

  static Map<int, double> workingWeightsKg(double oneRepMaxKg) {
    if (oneRepMaxKg <= 0) return const <int, double>{};
    return <int, double>{
      for (final percent in const <int>[60, 70, 75, 80, 85, 90])
        percent: oneRepMaxKg * (percent / 100),
    };
  }

  static double? paceSecondsPerKm({
    required double distanceKm,
    required int durationSeconds,
  }) {
    if (distanceKm <= 0 || durationSeconds <= 0) return null;
    return durationSeconds / distanceKm;
  }

  static int? durationFor({
    required double distanceKm,
    required double paceSecondsPerKm,
  }) {
    if (distanceKm <= 0 || paceSecondsPerKm <= 0) return null;
    return (distanceKm * paceSecondsPerKm).round();
  }

  static PlateLoadResult plateLoad({
    required double targetTotal,
    required double barWeight,
    required List<double> availablePlates,
  }) {
    final safeTarget = math.max(targetTotal, barWeight);
    var perSide = math.max(0, (safeTarget - barWeight) / 2);
    final plates = availablePlates.where((p) => p > 0).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    final selected = <double>[];

    for (final plate in plates) {
      while (perSide + 1e-9 >= plate) {
        selected.add(plate);
        perSide -= plate;
      }
    }

    final perSideLoaded = selected.fold<double>(0, (sum, p) => sum + p);
    final achieved = barWeight + (2 * perSideLoaded);
    return PlateLoadResult(
      targetTotal: targetTotal,
      barWeight: barWeight,
      platesPerSide: List<double>.unmodifiable(selected),
      achievedTotal: achieved,
    );
  }
}
