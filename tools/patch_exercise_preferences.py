from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise SystemExit(f'Expected snippet not found: {label}')
    return text.replace(old, new, 1)


# --- exercise_swap_service.dart ---
swap_path = Path('lib/exercise_swap_service.dart')
swap = swap_path.read_text()
swap = replace_once(
    swap,
    "import 'exercise_repository.dart';\n",
    "import 'exercise_favorite_store.dart';\nimport 'exercise_preference_ranking.dart';\nimport 'exercise_preference_store.dart';\nimport 'exercise_repository.dart';\n",
    'swap preference imports',
)
swap = replace_once(
    swap,
    """  final SupabaseClient client;
  final ExerciseRepository repository;
  final ProfileService profiles;

  ExerciseSwapService(this.client)
      : repository = ExerciseRepository(client),
        profiles = ProfileService(client);
""",
    """  final SupabaseClient client;
  final ExerciseRepository repository;
  final ProfileService profiles;
  final ExercisePreferenceStore preferences;
  final ExerciseFavoriteStore favorites;

  ExerciseSwapService(this.client)
      : repository = ExerciseRepository(client),
        profiles = ProfileService(client),
        preferences = ExercisePreferenceStore(
          userScope: client.auth.currentUser?.id ?? 'guest',
        ),
        favorites = ExerciseFavoriteStore(client);
""",
    'swap service fields',
)
swap = replace_once(
    swap,
    """    final preferredLocations = _strings(profileMap?['training_locations']).toSet();
    final homeEquipment = _strings(profileMap?['home_equipment']).toSet();
    final gymAccess = profileMap?['gym_access']?.toString();

    final ranked = <ExerciseSwapSuggestion>[];
""",
    """    final preferredLocations = _strings(profileMap?['training_locations']).toSet();
    final homeEquipment = _strings(profileMap?['home_equipment']).toSet();
    final gymAccess = profileMap?['gym_access']?.toString();
    final preferenceSnapshot = await preferences.load();
    final favoriteIds = await favorites.load();

    final ranked = <ExerciseSwapSuggestion>[];
""",
    'load preference signals',
)
swap = replace_once(
    swap,
    """      final scoring = ExerciseSwapRanker.score(
        current: current,
        candidate: candidate,
        reason: reason,
        unavailableEquipment: unavailableEquipment,
        homeEquipment: homeEquipment,
        gymAccess: gymAccess,
      );
      if (scoring.score <= 0) continue;

      ranked.add(
        ExerciseSwapSuggestion(
          exercise: _prescriptionFromCandidate(current, candidate),
          score: scoring.score,
          reasons: scoring.reasons,
        ),
      );
""",
    """      final scoring = ExerciseSwapRanker.score(
        current: current,
        candidate: candidate,
        reason: reason,
        unavailableEquipment: unavailableEquipment,
        homeEquipment: homeEquipment,
        gymAccess: gymAccess,
      );
      final preference = ExercisePreferenceRanking.adjustment(
        record: preferenceSnapshot.forExercise(candidate.name),
        favorite: favoriteIds.contains(candidate.id),
      );
      final finalScore = scoring.score + preference.scoreDelta;
      if (finalScore <= 0) continue;

      ranked.add(
        ExerciseSwapSuggestion(
          exercise: _prescriptionFromCandidate(current, candidate),
          score: finalScore,
          reasons: <String>{
            ...scoring.reasons,
            ...preference.reasons,
          }.take(3).toList(growable: false),
        ),
      );
""",
    'preference ranking adjustment',
)
swap = replace_once(
    swap,
    """  Future<void> saveSwap({
    required String workoutTitle,
""",
    """  Future<void> rejectSuggestion(String exerciseName) async {
    try {
      await preferences.recordRejectedSuggestion(exerciseName);
    } catch (_) {
      // Preference memory is helpful but must never block a workout.
    }
  }

  Future<void> saveSwap({
    required String workoutTitle,
""",
    'reject suggestion method',
)
swap = replace_once(
    swap,
    """  }) async {
    final now = DateTime.now();
    final record = {
      'workout_title': workoutTitle,
""",
    """  }) async {
    try {
      if (reason == ExerciseSwapReason.dislike) {
        await preferences.recordDislike(fromExercise);
      }
      await preferences.recordSelectedAlternative(toExercise);
    } catch (_) {
      // Learned preferences remain local-first and optional.
    }

    final now = DateTime.now();
    final record = {
      'workout_title': workoutTitle,
""",
    'learn from completed swap',
)
swap_path.write_text(swap)


# --- live_workout_screen.dart ---
live_path = Path('lib/live_workout_screen.dart')
live = live_path.read_text()
start_anchor = "    final selected = await showModalBottomSheet<ExerciseSwapSuggestion>(\n"
end_anchor = "\n    if (selected == null || !mounted) return;\n"
start = live.find(start_anchor)
if start < 0:
    raise SystemExit('Expected live swap sheet start not found')
end = live.find(end_anchor, start)
if end < 0:
    raise SystemExit('Expected live swap sheet end not found')
new_sheet = """    final rejectedInSheet = <String>{};
    final selected = await showModalBottomSheet<ExerciseSwapSuggestion>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final visibleSuggestions = result.suggestions
                .where(
                  (suggestion) =>
                      !rejectedInSheet.contains(suggestion.exercise.name),
                )
                .toList(growable: false);
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.72,
              minChildSize: 0.45,
              maxChildSize: 0.92,
              builder: (context, controller) {
                return ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    Text(
                      'Replace ${currentExercise.name}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF102A43),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Reason: ${reason.label}',
                      style: const TextStyle(color: Color(0xFF627D98)),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'LeanIt now learns from favourites, alternatives you choose and options you reject.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Color(0xFF829AB1),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (visibleSuggestions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4F8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'You rejected all current suggestions. Close this sheet and LeanIt will use that preference memory the next time alternatives are ranked.',
                          style: TextStyle(
                            height: 1.4,
                            color: Color(0xFF486581),
                          ),
                        ),
                      )
                    else
                      ...visibleSuggestions.map(
                        (suggestion) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 14, 10, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const CircleAvatar(
                                      backgroundColor: Color(0xFFE5F4F8),
                                      child: Icon(
                                        Icons.swap_horiz_rounded,
                                        color: Color(0xFF176B87),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            suggestion.exercise.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            [
                                              suggestion.exercise.target,
                                              suggestion.exercise.equipment,
                                              if (suggestion.reasons.isNotEmpty)
                                                suggestion.reasons.join(' • '),
                                            ].join('\\n'),
                                            style: const TextStyle(
                                              color: Color(0xFF627D98),
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: FilledButton.icon(
                                        onPressed: () => Navigator.pop(
                                          sheetContext,
                                          suggestion,
                                        ),
                                        icon: const Icon(Icons.check_rounded),
                                        label: const Text('USE THIS'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      onPressed: () async {
                                        await _swapService.rejectSuggestion(
                                          suggestion.exercise.name,
                                        );
                                        if (!mounted) return;
                                        setSheetState(() {
                                          rejectedInSheet
                                              .add(suggestion.exercise.name);
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.thumb_down_alt_outlined,
                                      ),
                                      label: const Text('NOT FOR ME'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
"""
live = live[:start] + new_sheet + live[end:]
live_path.write_text(live)


# --- account_screen.dart ---
account_path = Path('lib/account_screen.dart')
account = account_path.read_text()
account = replace_once(
    account,
    "import 'training_profile_edit_screen.dart';\n",
    "import 'training_profile_edit_screen.dart';\nimport 'exercise_preferences_screen.dart';\n",
    'account preference import',
)
account = replace_once(
    account,
    """              const SizedBox(height: 16),
              _section(
                title: 'LeanEat Analyzer',
""",
    """              const SizedBox(height: 16),
              _section(
                title: 'Exercise preferences',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'See what LeanIt has learned from your favourites, chosen alternatives and rejected exercises. You can forget any learned choice at any time.',
                      style: TextStyle(
                        height: 1.45,
                        color: Color(0xFF66766D),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const ExercisePreferencesScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.psychology_alt_outlined),
                        label: const Text('MANAGE EXERCISE PREFERENCES'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _section(
                title: 'LeanEat Analyzer',
""",
    'account preference section',
)
account_path.write_text(account)
