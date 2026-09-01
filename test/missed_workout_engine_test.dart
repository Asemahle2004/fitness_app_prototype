import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_prototype/missed_workout_engine.dart';
import 'package:fitness_app_prototype/programme_engine.dart';

PlannedSession session(
  String day,
  String title, {
  String intensity = 'Moderate',
}) {
  return PlannedSession(
    day: day,
    title: title,
    location: 'Gym',
    duration: '45 min',
    focus: title,
    intensity: intensity,
  );
}

void main() {
  group('MissedWorkoutEngine', () {
    test('moves a missed session to the nearest safe open available day', () {
      final result = MissedWorkoutEngine.recommend(
        sessions: <PlannedSession>[
          session('Monday', 'Upper Body A'),
          session('Wednesday', 'Lower Body A'),
          session('Friday', 'Upper Body B'),
        ],
        missedIndex: 0,
        availableDays: <String>{
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
        },
      );

      expect(result.recommended.action, MissedWorkoutAction.moveLater);
      expect(result.recommended.targetDay, 'Tuesday');
      expect(
        result.recommended.revisedSessions
            .any((item) => item.day == 'Tuesday' && item.title == 'Upper Body A'),
        isTrue,
      );
    });

    test('does not cram a hard run beside another hard run', () {
      final result = MissedWorkoutEngine.recommend(
        sessions: <PlannedSession>[
          session('Monday', 'Intervals', intensity: 'Hard'),
          session('Wednesday', 'Tempo Run', intensity: 'Hard'),
          session('Friday', 'Long Run'),
        ],
        missedIndex: 0,
        availableDays: <String>{'Monday', 'Tuesday', 'Wednesday', 'Friday'},
      );

      expect(result.recommended.action, MissedWorkoutAction.skipToday);
      expect(result.recommended.revisedSessions.length, 2);
    });

    test('avoids moving lower-body work beside another lower-body day', () {
      final result = MissedWorkoutEngine.recommend(
        sessions: <PlannedSession>[
          session('Monday', 'Lower Body A'),
          session('Wednesday', 'Lower Body B'),
          session('Friday', 'Upper Body'),
        ],
        missedIndex: 0,
        availableDays: <String>{'Monday', 'Tuesday', 'Wednesday', 'Friday'},
      );

      expect(result.recommended.action, MissedWorkoutAction.skipToday);
    });

    test('can move beside mobility because it is not conflicting loading', () {
      final result = MissedWorkoutEngine.recommend(
        sessions: <PlannedSession>[
          session('Monday', 'Full Body Strength'),
          session('Wednesday', 'Mobility + Core'),
          session('Friday', 'Full Body Conditioning'),
        ],
        missedIndex: 0,
        availableDays: <String>{
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
        },
      );

      expect(result.recommended.action, MissedWorkoutAction.moveLater);
      expect(result.recommended.targetDay, 'Tuesday');
    });

    test('offers continue-plan as an alternative without duplicating sessions', () {
      final sessions = <PlannedSession>[
        session('Monday', 'Upper Body'),
        session('Wednesday', 'Lower Body'),
      ];
      final result = MissedWorkoutEngine.recommend(
        sessions: sessions,
        missedIndex: 0,
        availableDays: <String>{'Monday', 'Wednesday'},
      );

      final continueOption = result.alternatives.firstWhere(
        (option) => option.action == MissedWorkoutAction.continuePlan,
      );
      expect(continueOption.revisedSessions.length, sessions.length);
      expect(
        continueOption.revisedSessions.map((item) => item.title).toList(),
        sessions.map((item) => item.title).toList(),
      );
    });
  });
}
