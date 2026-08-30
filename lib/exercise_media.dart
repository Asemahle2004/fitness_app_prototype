import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'exercise_repository.dart';
import 'movement_visual.dart';

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

  @override
  void initState() {
    super.initState();
    _repository = ExerciseRepository(Supabase.instance.client);
    _future = _repository.fetchByName(widget.exerciseName);
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
        errorBuilder: (_, __, ___) => MovementVisual(
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
    return FutureBuilder<OnlineExercise?>(
      future: _future,
      builder: (context, snapshot) {
        final online = snapshot.data;
        final imagePath = online?.imagePath;
        if (imagePath != null && imagePath.isNotEmpty) {
          return Image.network(
            _repository.publicImageUrl(imagePath),
            fit: widget.fit,
            errorBuilder: (_, __, ___) => _fallback(online?.movementPattern),
          );
        }
        return _fallback(online?.movementPattern);
      },
    );
  }
}
