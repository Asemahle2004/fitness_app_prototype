import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_prototype/progress_screen.dart';
import 'package:fitness_app_prototype/readiness_screen.dart';
import 'package:fitness_app_prototype/training_store.dart';

void main() {
  test('LeanIt v1 progress and readiness modules compile', () {
    expect(const ProgressScreen(), isNotNull);
    expect(const ReadinessScreen(), isNotNull);
    const record = ReadinessRecord(
      recordedAt: null,
      sleep: 3,
      energy: 3,
      soreness: 3,
      stress: 3,
    );
    expect(record.score, greaterThan(0));
  });
}
