import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_prototype/evidence_rule_engine.dart';

void main() {
  test('approvedFor never returns draft rules', () {
    final rules = EvidenceRuleRegistry.approvedFor(goal: 'strength');
    expect(rules, isNotEmpty);
    expect(rules.every((rule) => rule.canDriveAutomation), isTrue);
    expect(
      rules.any((rule) => rule.id == 'experimental_high_frequency'),
      isFalse,
    );
  });

  test('experimental high-frequency rule remains blocked', () {
    final rule = EvidenceRuleRegistry.byId('experimental_high_frequency');
    expect(rule, isNotNull);
    expect(rule!.reviewStatus, EvidenceReviewStatus.draft);
    expect(rule.canDriveAutomation, isFalse);
  });

  test('sprint approved rules are discoverable for 100 m', () {
    final rules = EvidenceRuleRegistry.approvedFor(
      goal: '100 m',
      environment: 'outside',
    );
    expect(
      rules.any((rule) => rule.id == 'sprint_acceleration_quality'),
      isTrue,
    );
  });
}
