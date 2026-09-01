import 'adaptive_strength_engine.dart';

class StrengthAdaptationCache {
  static StrengthAdaptationRecommendation? current;

  const StrengthAdaptationCache._();

  static void set(StrengthAdaptationRecommendation recommendation) {
    current = recommendation;
  }

  static void clear() {
    current = null;
  }
}
