import 'adaptive_strength_engine.dart';
import 'periodization_engine.dart';

class TrainingDecisionExplanation {
  final String decision;
  final String whatChanges;
  final String why;
  final List<String> evidence;

  const TrainingDecisionExplanation({
    required this.decision,
    required this.whatChanges,
    required this.why,
    required this.evidence,
  });
}

class TrainingDecisionExplainer {
  const TrainingDecisionExplainer._();

  static TrainingDecisionExplanation explain({
    StrengthAdaptationRecommendation? strength,
    PeriodizationPlan? periodization,
  }) {
    final strengthAction = strength?.action;
    final phase = periodization?.phase;

    if (strengthAction == StrengthAdaptationAction.deload ||
        phase == TrainingBlockPhase.deload) {
      return TrainingDecisionExplanation(
        decision: 'DELOAD',
        whatChanges:
            'Fewer working sets, no drop sets, easier loading and more recovery between hard sessions.',
        why:
            'LeanIt found enough recovery/fatigue evidence that adding more training stress would be a poor next step.',
        evidence: [
          ...?strength?.reasons,
          ...?periodization?.reasons,
        ],
      );
    }

    if (strengthAction == StrengthAdaptationAction.reduce) {
      return TrainingDecisionExplanation(
        decision: 'REDUCE',
        whatChanges:
            'Keep the movement pattern but trim working volume and avoid another progression jump.',
        why:
            'Training load has risen faster than the available recovery evidence supports.',
        evidence: strength?.reasons ?? const <String>[],
      );
    }

    if (strengthAction == StrengthAdaptationAction.maintain ||
        phase == TrainingBlockPhase.consolidate) {
      return TrainingDecisionExplanation(
        decision: 'HOLD / CONSOLIDATE',
        whatChanges:
            'Repeat a controlled training dose before increasing load, reps or intensity techniques.',
        why:
            'The current dose still needs to become repeatable before LeanIt adds more.',
        evidence: [
          ...?strength?.reasons,
          ...?periodization?.reasons,
        ],
      );
    }

    if (strengthAction == StrengthAdaptationAction.progress) {
      return TrainingDecisionExplanation(
        decision: 'PROGRESS',
        whatChanges:
            'Use the normal double-progression target while keeping weekly increases bounded.',
        why:
            'Recent performance and recovery signals support a measured increase.',
        evidence: [
          ...?strength?.reasons,
          ...?periodization?.reasons,
        ],
      );
    }

    return TrainingDecisionExplanation(
      decision: 'BUILD BASELINE',
      whatChanges:
          'Keep training controlled while LeanIt gathers enough repeatable performance data.',
      why:
          'Automatic progression is intentionally withheld when recent evidence is still limited.',
      evidence: [
        ...?strength?.reasons,
        ...?periodization?.reasons,
      ],
    );
  }
}
