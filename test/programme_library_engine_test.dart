import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_prototype/evidence_rule_engine.dart';
import 'package:fitness_app_prototype/programme_library_engine.dart';

void main() {
  test('programme template IDs are unique', () {
    final ids = ProgrammeLibraryEngine.templates.map((item) => item.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('approved templates have the expected weekly session count', () {
    for (final template in ProgrammeLibraryEngine.templates.where((item) => item.approved)) {
      expect(template.sessions.length, template.daysPerWeek);
      expect(template.weeks, inInclusiveRange(4, 12));
    }
  });

  test('every approved template references approved evidence rules', () {
    for (final template in ProgrammeLibraryEngine.templates.where((item) => item.approved)) {
      expect(template.evidenceRuleIds, isNotEmpty);
      for (final id in template.evidenceRuleIds) {
        final rule = EvidenceRuleRegistry.byId(id);
        expect(rule, isNotNull, reason: '${template.id} references missing $id');
        expect(
          rule!.reviewStatus,
          EvidenceReviewStatus.approved,
          reason: '${template.id} references non-approved $id',
        );
      }
    }
  });

  test('sprint support template is available for 100 m athletes', () {
    final matching = ProgrammeLibraryEngine.approved(
      goal: '100 m',
      level: 'Intermediate',
      equipment: {'Track', 'Gym'},
    );
    expect(matching.any((item) => item.id == 'sprint_support_4'), isTrue);
  });
}
