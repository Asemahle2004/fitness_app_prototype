import 'package:fitness_app_prototype/training_profile_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('old single goal profile remains compatible', () {
    final context = TrainingProfileContext.fromMap({
      'main_goal': 'Build Muscle',
      'experience': 'Beginner',
      'fitness_level': 'Low',
      'activity_level': 'Lightly active',
      'session_length': '45 min',
      'training_time': 'Evening',
    });
    expect(context.goals, ['Build Muscle']);
    expect(context.mainGoal, 'Build Muscle');
  });

  test('multiple goals keep main goal and concurrent intent', () {
    final context = TrainingProfileContext.fromMap({
      'main_goal': 'Build Muscle',
      'goals': ['Build Muscle', 'Lose Body Fat', 'Improve Running Performance'],
      'experience': 'Intermediate',
      'fitness_level': 'Moderate',
      'activity_level': 'Moderately active',
      'session_length': '60 min',
      'training_time': 'Morning',
    });
    expect(context.wantsStrength, isTrue);
    expect(context.wantsFatLoss, isTrue);
    expect(context.wantsRunning, isTrue);
    expect(context.goals.length, 3);
  });
}
