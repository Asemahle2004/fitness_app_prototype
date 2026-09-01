import 'training_settings.dart';
import 'training_tools_engine.dart';

/// Presentation/input conversion layer for LeanIt.
///
/// Persisted training data stays canonical (kg, km/metres, cm). Screens may
/// read/write in the member's preferred units through this cache without
/// rewriting historical records.
class UnitDisplay {
  UnitDisplay._();

  static UnitSystem _system = UnitSystem.metric;

  static UnitSystem get system => _system;
  static bool get isMetric => _system == UnitSystem.metric;
  static String get weightUnit => isMetric ? 'kg' : 'lb';
  static String get distanceUnit => isMetric ? 'km' : 'mi';
  static String get lengthUnit => isMetric ? 'cm' : 'in';
  static String get paceUnit => isMetric ? '/km' : '/mi';

  static void setSystem(UnitSystem system) => _system = system;

  static Future<void> refresh({required String userScope}) async {
    final settings = await TrainingSettingsStore(userScope: userScope).load();
    _system = settings.unitSystem;
  }

  static double canonicalWeight(double entered) =>
      TrainingToolsEngine.toCanonicalWeight(entered, _system);

  static double displayWeightValue(double kg) =>
      TrainingToolsEngine.fromCanonicalWeight(kg, _system);

  static double canonicalDistanceKm(double entered) =>
      TrainingToolsEngine.toCanonicalDistanceKm(entered, _system);

  static double displayDistanceKm(double km) =>
      TrainingToolsEngine.fromCanonicalDistanceKm(km, _system);

  static double canonicalLengthCm(double entered) => isMetric
      ? entered
      : TrainingToolsEngine.inchesToCm(entered);

  static double displayLengthValue(double cm) => isMetric
      ? cm
      : TrainingToolsEngine.cmToInches(cm);

  static String formatWeight(double kg, {int decimals = 1}) =>
      TrainingToolsEngine.formatWeight(kg, _system, decimals: decimals);

  static String formatWeightValue(double kg, {int decimals = 1}) {
    final value = displayWeightValue(kg);
    return _number(value, decimals: decimals);
  }

  static String formatDistanceMeters(double meters, {int decimals = 2}) {
    final km = meters / 1000;
    final value = displayDistanceKm(km);
    return '${_number(value, decimals: decimals)} $distanceUnit';
  }

  static String formatDistanceKm(double km, {int decimals = 2}) {
    final value = displayDistanceKm(km);
    return '${_number(value, decimals: decimals)} $distanceUnit';
  }

  static String formatPace(double? secondsPerKm) =>
      TrainingToolsEngine.formatPace(secondsPerKm, _system);

  static String formatLengthCm(double cm, {bool heightStyle = false}) {
    if (isMetric) return '${_number(cm, decimals: 1)} cm';
    final inches = TrainingToolsEngine.cmToInches(cm);
    if (!heightStyle) return '${_number(inches, decimals: 1)} in';
    final whole = inches.round();
    final feet = whole ~/ 12;
    final remainder = whole % 12;
    return '$feet ft $remainder in';
  }

  static String _number(double value, {int decimals = 1}) {
    if ((value - value.round()).abs() < 0.0001) return value.toStringAsFixed(0);
    return value.toStringAsFixed(decimals);
  }
}
