import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExerciseFavoriteStore {
  static const _baseKey = 'leanit_exercise_favorites_v1';

  final SupabaseClient? _client;
  final String? _userIdOverride;

  const ExerciseFavoriteStore(SupabaseClient client)
      : _client = client,
        _userIdOverride = null;

  const ExerciseFavoriteStore.forUser(String? userId)
      : _client = null,
        _userIdOverride = userId;

  String get _storageKey {
    final userId = _userIdOverride ?? _client?.auth.currentUser?.id;
    return userId == null || userId.trim().isEmpty
        ? '${_baseKey}_guest'
        : '${_baseKey}_${userId.trim()}';
  }

  Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_storageKey) ?? const <String>[];
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  Future<void> setFavorite(String exerciseId, bool favorite) async {
    final id = exerciseId.trim();
    if (id.isEmpty) return;

    final favorites = await load();
    if (favorite) {
      favorites.add(id);
    } else {
      favorites.remove(id);
    }
    await _write(favorites);
  }

  Future<bool> toggle(String exerciseId) async {
    final id = exerciseId.trim();
    if (id.isEmpty) return false;

    final favorites = await load();
    final nowFavorite = !favorites.contains(id);
    if (nowFavorite) {
      favorites.add(id);
    } else {
      favorites.remove(id);
    }
    await _write(favorites);
    return nowFavorite;
  }

  Future<void> remove(String exerciseId) => setFavorite(exerciseId, false);

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _write(Set<String> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    final values = favorites.toList(growable: false)..sort();
    await prefs.setStringList(_storageKey, values);
  }
}
