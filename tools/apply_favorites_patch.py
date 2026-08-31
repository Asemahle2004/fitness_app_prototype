from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text(encoding='utf-8')
    if old not in text:
        raise RuntimeError(f'Expected block not found in {path}: {old[:120]!r}')
    file.write_text(text.replace(old, new, 1), encoding='utf-8')


path = 'lib/exercise_library_screen.dart'

replace_once(
    path,
    "import 'package:flutter/material.dart';\n",
    "import 'dart:async';\n\nimport 'package:flutter/material.dart';\n",
)

replace_once(
    path,
    "import 'custom_exercise_store.dart';\nimport 'exercise_media.dart';\n",
    "import 'custom_exercise_store.dart';\nimport 'exercise_favorite_store.dart';\nimport 'exercise_media.dart';\n",
)

replace_once(
    path,
    "  late final CustomExerciseStore _customStore;\n  late Future<List<OnlineExercise>> _future;\n",
    "  late final CustomExerciseStore _customStore;\n  late final ExerciseFavoriteStore _favoriteStore;\n  late Future<List<OnlineExercise>> _future;\n",
)

replace_once(
    path,
    "  final Set<String> _selectedNames = {};\n  String _search = '';\n",
    "  final Set<String> _selectedNames = {};\n  final Set<String> _favoriteIds = {};\n  String _search = '';\n",
)

replace_once(
    path,
    "  String? _location;\n\n  @override\n",
    "  String? _location;\n  bool _favoritesOnly = false;\n\n  @override\n",
)

replace_once(
    path,
    "    _repository = ExerciseRepository(widget.client);\n    _customStore = CustomExerciseStore(widget.client);\n    _future = _loadAll();\n",
    "    _repository = ExerciseRepository(widget.client);\n    _customStore = CustomExerciseStore(widget.client);\n    _favoriteStore = ExerciseFavoriteStore(widget.client);\n    _future = _loadAll();\n    unawaited(_loadFavorites());\n",
)

replace_once(
    path,
    "  Future<List<OnlineExercise>> _loadAll() async {\n",
    "  Future<void> _loadFavorites() async {\n    try {\n      final favorites = await _favoriteStore.load();\n      if (!mounted) return;\n      setState(() {\n        _favoriteIds\n          ..clear()\n          ..addAll(favorites);\n      });\n    } catch (_) {}\n  }\n\n  Future<void> _toggleFavorite(OnlineExercise exercise) async {\n    final id = exercise.id.trim();\n    if (id.isEmpty) return;\n    final wasFavorite = _favoriteIds.contains(id);\n    setState(() {\n      if (wasFavorite) {\n        _favoriteIds.remove(id);\n      } else {\n        _favoriteIds.add(id);\n      }\n    });\n\n    try {\n      await _favoriteStore.setFavorite(id, !wasFavorite);\n    } catch (_) {\n      if (!mounted) return;\n      setState(() {\n        if (wasFavorite) {\n          _favoriteIds.add(id);\n        } else {\n          _favoriteIds.remove(id);\n        }\n      });\n      ScaffoldMessenger.of(context).showSnackBar(\n        const SnackBar(content: Text('Could not update favorites.')),\n      );\n    }\n  }\n\n  Future<List<OnlineExercise>> _loadAll() async {\n",
)

replace_once(
    path,
    "      return (query.isEmpty || searchText.contains(query)) &&\n          (_category == null || exercise.category == _category) &&\n          (_difficulty == null || exercise.difficulty == _difficulty) &&\n          (_location == null || exercise.locations.contains(_location));\n",
    "      return (query.isEmpty || searchText.contains(query)) &&\n          (!_favoritesOnly || _favoriteIds.contains(exercise.id)) &&\n          (_category == null || exercise.category == _category) &&\n          (_difficulty == null || exercise.difficulty == _difficulty) &&\n          (_location == null || exercise.locations.contains(_location));\n",
)

replace_once(
    path,
    "    await _customStore.delete(exercise.id);\n    _selectedNames.remove(exercise.name);\n",
    "    await _customStore.delete(exercise.id);\n    await _favoriteStore.remove(exercise.id);\n    _favoriteIds.remove(exercise.id);\n    _selectedNames.remove(exercise.name);\n",
)

replace_once(
    path,
    "                          _FilterMenu(\n                            label: _location ?? 'Location',\n                            values: const ['Home', 'Gym', 'Outside'],\n                            onSelected: (value) => setState(() => _location = value),\n                            onClear: () => setState(() => _location = null),\n                          ),\n",
    "                          _FilterMenu(\n                            label: _location ?? 'Location',\n                            values: const ['Home', 'Gym', 'Outside'],\n                            onSelected: (value) => setState(() => _location = value),\n                            onClear: () => setState(() => _location = null),\n                          ),\n                          const SizedBox(width: 8),\n                          FilterChip(\n                            selected: _favoritesOnly,\n                            avatar: Icon(\n                              _favoritesOnly\n                                  ? Icons.favorite_rounded\n                                  : Icons.favorite_border_rounded,\n                              size: 17,\n                            ),\n                            label: Text('Favorites (${_favoriteIds.length})'),\n                            onSelected: (value) =>\n                                setState(() => _favoritesOnly = value),\n                          ),\n",
)

replace_once(
    path,
    "                          final selected = _selectedNames.contains(exercise.name);\n                          return Container(\n",
    "                          final selected = _selectedNames.contains(exercise.name);\n                          final favorite = _favoriteIds.contains(exercise.id);\n                          return Container(\n",
)

replace_once(
    path,
    "                              const Text('No exercises match these filters.'),\n",
    "                              Text(\n                                _favoritesOnly\n                                    ? 'No favorite exercises match these filters.'\n                                    : 'No exercises match these filters.',\n                              ),\n",
)

old_trailing = """                                    if (widget.selectionMode)
                                      Checkbox(
                                        value: selected,
                                        onChanged: allowed
                                            ? (_) {
                                                setState(() {
                                                  if (selected) {
                                                    _selectedNames.remove(exercise.name);
                                                  } else {
                                                    _selectedNames.add(exercise.name);
                                                  }
                                                });
                                              }
                                            : null,
                                      )
                                    else if (custom)
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'edit') _editCustomExercise(exercise);
                                          if (value == 'delete') _deleteCustomExercise(exercise);
                                        },
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                                        ],
                                      )
                                    else
                                      IconButton(
                                        tooltip: 'Exercise details',
                                        onPressed: () => _openDetail(exercise),
                                        icon: const Icon(Icons.chevron_right, color: Color(0xFF9FB3C8)),
                                      ),
"""
new_trailing = """                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: favorite
                                              ? 'Remove from favorites'
                                              : 'Add to favorites',
                                          onPressed: () => _toggleFavorite(exercise),
                                          icon: Icon(
                                            favorite
                                                ? Icons.favorite_rounded
                                                : Icons.favorite_border_rounded,
                                            color: favorite
                                                ? const Color(0xFFD64545)
                                                : const Color(0xFF829AB1),
                                          ),
                                        ),
                                        if (widget.selectionMode)
                                          Checkbox(
                                            value: selected,
                                            onChanged: allowed
                                                ? (_) {
                                                    setState(() {
                                                      if (selected) {
                                                        _selectedNames.remove(exercise.name);
                                                      } else {
                                                        _selectedNames.add(exercise.name);
                                                      }
                                                    });
                                                  }
                                                : null,
                                          )
                                        else if (custom)
                                          PopupMenuButton<String>(
                                            onSelected: (value) {
                                              if (value == 'edit') _editCustomExercise(exercise);
                                              if (value == 'delete') _deleteCustomExercise(exercise);
                                            },
                                            itemBuilder: (_) => const [
                                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                                              PopupMenuItem(value: 'delete', child: Text('Delete')),
                                            ],
                                          )
                                        else
                                          IconButton(
                                            tooltip: 'Exercise details',
                                            onPressed: () => _openDetail(exercise),
                                            icon: const Icon(
                                              Icons.chevron_right,
                                              color: Color(0xFF9FB3C8),
                                            ),
                                          ),
                                      ],
                                    ),
"""
replace_once(path, old_trailing, new_trailing)
