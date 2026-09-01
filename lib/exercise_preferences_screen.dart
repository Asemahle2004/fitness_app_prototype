import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'exercise_favorite_store.dart';
import 'exercise_preference_store.dart';
import 'exercise_repository.dart';

class _ExercisePreferencesView {
  final List<ExercisePreferenceRecord> learned;
  final List<String> favorites;

  const _ExercisePreferencesView({
    required this.learned,
    required this.favorites,
  });
}

class ExercisePreferencesScreen extends StatefulWidget {
  const ExercisePreferencesScreen({super.key});

  @override
  State<ExercisePreferencesScreen> createState() =>
      _ExercisePreferencesScreenState();
}

class _ExercisePreferencesScreenState
    extends State<ExercisePreferencesScreen> {
  late final SupabaseClient _client;
  late final ExercisePreferenceStore _preferences;
  late final ExerciseFavoriteStore _favorites;
  late Future<_ExercisePreferencesView> _future;

  @override
  void initState() {
    super.initState();
    _client = Supabase.instance.client;
    _preferences = ExercisePreferenceStore(
      userScope: _client.auth.currentUser?.id ?? 'guest',
    );
    _favorites = ExerciseFavoriteStore(_client);
    _future = _load();
  }

  Future<_ExercisePreferencesView> _load() async {
    final preferenceSnapshot = await _preferences.load();
    final favoriteIds = await _favorites.load();
    final catalogue = await ExerciseRepository(_client).fetchAll();
    final namesById = <String, String>{
      for (final exercise in catalogue) exercise.id: exercise.name,
    };
    final favoriteNames = favoriteIds
        .map((id) => namesById[id] ?? id)
        .toList(growable: false)
      ..sort();
    final learned = preferenceSnapshot.records.values.toList(growable: false)
      ..sort((a, b) {
        final score = b.score.compareTo(a.score);
        if (score != 0) return score;
        return a.exerciseName.compareTo(b.exerciseName);
      });
    return _ExercisePreferencesView(
      learned: learned,
      favorites: favoriteNames,
    );
  }

  void _reload() {
    setState(() => _future = _load());
  }

  Future<void> _clearExercise(ExercisePreferenceRecord record) async {
    await _preferences.clearExercise(record.exerciseName);
    if (!mounted) return;
    _reload();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Forgot learned preference for ${record.exerciseName}.')),
    );
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Forget learned preferences?'),
        content: const Text(
          'This clears only LeanIt’s learned exercise choices. Your favourites, workout history and programme stay unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('FORGET LEARNED CHOICES'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _preferences.clearAll();
    if (!mounted) return;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Exercise preferences'),
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: FutureBuilder<_ExercisePreferencesView>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('LeanIt could not load exercise preferences right now.'),
              ),
            );
          }
          final view = snapshot.data ??
              const _ExercisePreferencesView(
                learned: <ExercisePreferenceRecord>[],
                favorites: <String>[],
              );
          final preferred = view.learned
              .where((record) => record.score > 0)
              .toList(growable: false);
          final avoided = view.learned
              .where((record) => record.score < 0)
              .toList(growable: false)
            ..sort((a, b) => a.score.compareTo(b.score));

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7FA),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFB6E0EA)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.psychology_alt_outlined, color: Color(0xFF176B87)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'LeanIt learns from favourites, alternatives you choose and exercises you reject. Preferences only rank exercises that already pass safety, equipment and programme-purpose checks.',
                        style: TextStyle(
                          height: 1.45,
                          color: Color(0xFF486581),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _heading('Favourites', Icons.star_rounded),
              const SizedBox(height: 8),
              if (view.favorites.isEmpty)
                _empty('Star exercises in the Exercise Library to favour them when a suitable replacement is needed.')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: view.favorites
                      .map(
                        (name) => Chip(
                          avatar: const Icon(Icons.star_rounded, size: 18),
                          label: Text(name),
                        ),
                      )
                      .toList(growable: false),
                ),
              const SizedBox(height: 24),
              _heading('LeanIt has learned you prefer', Icons.thumb_up_alt_outlined),
              const SizedBox(height: 8),
              if (preferred.isEmpty)
                _empty('Choose suitable alternatives a few times and LeanIt will start learning what you prefer.')
              else
                ...preferred.map((record) => _recordCard(record, positive: true)),
              const SizedBox(height: 24),
              _heading('Avoid where possible', Icons.thumb_down_alt_outlined),
              const SizedBox(height: 8),
              if (avoided.isEmpty)
                _empty('Exercises you explicitly dislike or reject will appear here.')
              else
                ...avoided.map((record) => _recordCard(record, positive: false)),
              if (view.learned.isNotEmpty) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _clearAll,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('FORGET ALL LEARNED CHOICES'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _heading(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF176B87)),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Color(0xFF102A43),
            ),
          ),
        ),
      ],
    );
  }

  Widget _empty(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9E2EC)),
      ),
      child: Text(
        message,
        style: const TextStyle(height: 1.4, color: Color(0xFF627D98)),
      ),
    );
  }

  Widget _recordCard(ExercisePreferenceRecord record, {required bool positive}) {
    final details = <String>[
      if (record.selectedAlternativeCount > 0)
        'chosen ${record.selectedAlternativeCount}×',
      if (record.dislikeCount > 0) 'disliked ${record.dislikeCount}×',
      if (record.rejectedSuggestionCount > 0)
        'rejected ${record.rejectedSuggestionCount}×',
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              positive ? const Color(0xFFEAF7FA) : const Color(0xFFFFF3E0),
          child: Icon(
            positive ? Icons.thumb_up_alt_outlined : Icons.thumb_down_alt_outlined,
            color: positive ? const Color(0xFF176B87) : const Color(0xFF9A6700),
          ),
        ),
        title: Text(
          record.exerciseName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          details.isEmpty ? 'Learned preference' : details.join(' • '),
        ),
        trailing: IconButton(
          tooltip: 'Forget this preference',
          onPressed: () => _clearExercise(record),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
    );
  }
}
