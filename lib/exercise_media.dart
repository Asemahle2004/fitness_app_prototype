import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'exercise_repository.dart';
import 'movement_visual.dart';
import 'profile_service.dart';

class ExerciseMedia extends StatefulWidget {
  final String exerciseName;
  final String? localAsset;
  final String? movementPattern;
  final BoxFit fit;

  const ExerciseMedia({
    super.key,
    required this.exerciseName,
    this.localAsset,
    this.movementPattern,
    this.fit = BoxFit.contain,
  });

  @override
  State<ExerciseMedia> createState() => _ExerciseMediaState();
}

class _ExerciseMediaState extends State<ExerciseMedia> {
  late final ExerciseRepository _repository;
  late Future<OnlineExercise?> _future;
  late Future<LeanEatProfile?> _profileFuture;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _repository = ExerciseRepository(client);
    _future = _repository.fetchByName(widget.exerciseName);
    _profileFuture = ProfileService(client).currentProfile();
  }

  @override
  void didUpdateWidget(covariant ExerciseMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exerciseName != widget.exerciseName) {
      _future = _repository.fetchByName(widget.exerciseName);
    }
  }

  Widget _fallback([String? movementPattern]) {
    final asset = widget.localAsset;
    if (asset != null && asset.isNotEmpty) {
      return Image.asset(
        asset,
        fit: widget.fit,
        errorBuilder: (_, _, _) => MovementVisual(
          exerciseName: widget.exerciseName,
          movementPattern: movementPattern ?? widget.movementPattern,
        ),
      );
    }
    return MovementVisual(
      exerciseName: widget.exerciseName,
      movementPattern: movementPattern ?? widget.movementPattern,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Object?>>(
      future: Future.wait<Object?>([_future, _profileFuture]),
      builder: (context, snapshot) {
        final values = snapshot.data;
        final online = values != null && values.isNotEmpty ? values[0] as OnlineExercise? : null;
        final profile = values != null && values.length > 1 ? values[1] as LeanEatProfile? : null;
        final imagePath = online?.imageForSex(profile?.preferredVisualSex);
        if (imagePath != null && imagePath.isNotEmpty) {
          return Image.network(
            _repository.publicImageUrl(imagePath),
            fit: widget.fit,
            errorBuilder: (_, _, _) => _fallback(online?.movementPattern),
          );
        }
        return _fallback(online?.movementPattern);
      },
    );
  }
}
