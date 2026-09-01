from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text(encoding='utf-8')
    if old not in text:
        raise RuntimeError(f'Patch anchor missing in {path}: {old[:180]}')
    file.write_text(text.replace(old, new, 1), encoding='utf-8')


path = 'lib/exercise_repository.dart'

replace_once(
    path,
    "  static const String _freeCatalogueCacheTimeKey =\n      'leanit_free_exercise_catalogue_cached_at_v1';\n  static const Duration _freeCatalogueCacheMaxAge = Duration(days: 7);\n",
    "  static const String _freeCatalogueCacheTimeKey =\n      'leanit_free_exercise_catalogue_cached_at_v1';\n  static const String _mergedCatalogueCacheKey =\n      'leanit_exercise_catalogue_offline_v1';\n  static const String _mergedCatalogueCacheTimeKey =\n      'leanit_exercise_catalogue_offline_cached_at_v1';\n  static const Duration _freeCatalogueCacheMaxAge = Duration(days: 7);\n  static const Duration _mergedCatalogueCacheMaxAge = Duration(days: 7);\n  static const Duration _networkCatalogueTimeout = Duration(seconds: 4);\n",
)

replace_once(
    path,
    "  Future<OnlineExercise?> fetchByName(String name) async {\n    final exerciseId = idFromName(name);\n    final byId = await fetchById(exerciseId);\n",
    "  Future<OnlineExercise?> fetchByName(String name) async {\n    final exerciseId = idFromName(name);\n\n    // The merged metadata cache is checked before any network request. This is\n    // what lets CachedNetworkImage find an already-cached photo while offline.\n    final cached = await _readMergedCatalogueCache();\n    final lower = name.trim().toLowerCase();\n    for (final exercise in cached) {\n      if (exercise.id == exerciseId || exercise.name.toLowerCase() == lower) {\n        return exercise;\n      }\n    }\n    final cachedClosest = closestNameMatch(name, cached);\n    if (cachedClosest != null) return cachedClosest;\n\n    // Every WorkoutEngine movement exists in the compact built-in catalogue,\n    // so a first-ever offline programme never waits for the network merely to\n    // resolve its exercise metadata.\n    for (final offlineName in offlineProgrammeExerciseNames) {\n      final exercise = _offlineProgrammeExercise(offlineName);\n      if (exercise.id == exerciseId || exercise.name.toLowerCase() == lower) {\n        return exercise;\n      }\n    }\n\n    final byId = await fetchById(exerciseId);\n",
)

replace_once(
    path,
    "    final lower = name.trim().toLowerCase();\n    final catalogue = await _freeCatalogueSafely();\n",
    "    final catalogue = await _freeCatalogueSafely();\n",
)

replace_once(
    path,
    "  Future<OnlineExercise?> fetchById(String exerciseId) async {\n    try {\n",
    "  Future<OnlineExercise?> fetchById(String exerciseId) async {\n    final cached = await _readMergedCatalogueCache();\n    for (final exercise in cached) {\n      if (exercise.id == exerciseId) return exercise;\n    }\n    for (final name in offlineProgrammeExerciseNames) {\n      final exercise = _offlineProgrammeExercise(name);\n      if (exercise.id == exerciseId) return exercise;\n    }\n\n    try {\n",
)

replace_once(
    path,
    "          .eq('id', exerciseId)\n          .eq('is_active', true)\n          .maybeSingle();\n",
    "          .eq('id', exerciseId)\n          .eq('is_active', true)\n          .maybeSingle()\n          .timeout(_networkCatalogueTimeout);\n",
)

# Replace fetchAll with a cache-first implementation. The actual network merge
# lives in a helper so stale-cache refresh cannot recurse back into fetchAll.
start = "  Future<List<OnlineExercise>> fetchAll() async {\n"
end = "  Future<List<OnlineExercise>> searchByName(String query) async {\n"
file = Path(path)
text = file.read_text(encoding='utf-8')
start_index = text.find(start)
end_index = text.find(end)
if start_index == -1 or end_index == -1 or end_index <= start_index:
    raise RuntimeError('Could not locate ExerciseRepository.fetchAll block')

replacement = '''  Future<List<OnlineExercise>> fetchAll() async {\n    final cached = await _readMergedCatalogueCache();\n    if (cached.isNotEmpty) {\n      final merged = <String, OnlineExercise>{};\n      for (final name in offlineProgrammeExerciseNames) {\n        final exercise = _offlineProgrammeExercise(name);\n        merged[exercise.id] = exercise;\n      }\n      for (final exercise in cached) {\n        merged[exercise.id] = exercise;\n      }\n\n      if (await _mergedCacheIsStale()) {\n        unawaited(_refreshMergedCatalogueCache());\n      }\n\n      final result = merged.values.toList(growable: false)\n        ..sort((a, b) =>\n            a.name.toLowerCase().compareTo(b.name.toLowerCase()));\n      return result;\n    }\n\n    return _refreshMergedCatalogueCache();\n  }\n\n  Future<List<OnlineExercise>> _refreshMergedCatalogueCache() async {\n    final merged = <String, OnlineExercise>{};\n    for (final name in offlineProgrammeExerciseNames) {\n      final exercise = _offlineProgrammeExercise(name);\n      merged[exercise.id] = exercise;\n    }\n\n    final results = await Future.wait<List<OnlineExercise>>([\n      _freeCatalogueSafely().timeout(\n        _networkCatalogueTimeout,\n        onTimeout: () => const <OnlineExercise>[],\n      ),\n      _fetchCloudExercisesSafely(),\n    ]);\n\n    for (final exercise in results[0].take(freeCatalogueLimit)) {\n      merged[exercise.id] = exercise;\n    }\n    for (final exercise in results[1]) {\n      // LeanIt/Supabase records win over free and built-in records.\n      merged[exercise.id] = exercise;\n    }\n\n    final result = merged.values.toList(growable: false)\n      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));\n    await _writeMergedCatalogueCache(result);\n    return result;\n  }\n\n  Future<List<OnlineExercise>> _fetchCloudExercisesSafely() async {\n    try {\n      final data = await client\n          .from('exercises')\n          .select()\n          .eq('is_active', true)\n          .order('name')\n          .timeout(_networkCatalogueTimeout);\n      return (data as List)\n          .whereType<Map<String, dynamic>>()\n          .map(OnlineExercise.fromMap)\n          .toList(growable: false);\n    } catch (_) {\n      return const <OnlineExercise>[];\n    }\n  }\n\n  Future<List<OnlineExercise>> _readMergedCatalogueCache() async {\n    final prefs = await SharedPreferences.getInstance();\n    final raw = prefs.getString(_mergedCatalogueCacheKey);\n    if (raw == null || raw.trim().isEmpty) return const <OnlineExercise>[];\n    try {\n      final decoded = jsonDecode(raw);\n      if (decoded is! List) return const <OnlineExercise>[];\n      final exercises = <OnlineExercise>[];\n      for (final item in decoded) {\n        if (item is Map) {\n          exercises.add(\n            OnlineExercise.fromMap(Map<String, dynamic>.from(item)),\n          );\n        }\n      }\n      return exercises;\n    } catch (_) {\n      return const <OnlineExercise>[];\n    }\n  }\n\n  Future<void> _writeMergedCatalogueCache(\n    List<OnlineExercise> exercises,\n  ) async {\n    final prefs = await SharedPreferences.getInstance();\n    // Metadata is compact JSON. Images remain on-demand and are cached at a\n    // reduced resolution by ExerciseMedia, keeping total device storage low.\n    await prefs.setString(\n      _mergedCatalogueCacheKey,\n      jsonEncode(exercises.map((exercise) => exercise.toCacheMap()).toList()),\n    );\n    await prefs.setInt(\n      _mergedCatalogueCacheTimeKey,\n      DateTime.now().millisecondsSinceEpoch,\n    );\n  }\n\n  Future<bool> _mergedCacheIsStale() async {\n    final prefs = await SharedPreferences.getInstance();\n    final millis = prefs.getInt(_mergedCatalogueCacheTimeKey) ?? 0;\n    if (millis == 0) return true;\n    final cachedAt = DateTime.fromMillisecondsSinceEpoch(millis);\n    return DateTime.now().difference(cachedAt) > _mergedCatalogueCacheMaxAge;\n  }\n\n'''
text = text[:start_index] + replacement + text[end_index:]
file.write_text(text, encoding='utf-8')

# First-ever catalogue acquisition should not hold an offline library screen for
# 12 seconds. Four seconds is enough to populate the richer cache when online;
# the built-in catalogue remains immediately usable if the request times out.
replace_once(
    path,
    ".timeout(const Duration(seconds: 12));\n",
    ".timeout(_networkCatalogueTimeout);\n",
)
