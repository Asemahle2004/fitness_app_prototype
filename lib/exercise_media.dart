import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'exercise_curation.dart';
import 'exercise_repository.dart';
import 'profile_service.dart';

class ExerciseMedia extends StatefulWidget {
  final String exerciseName;
  final String? localAsset;
  final String? movementPattern;
  final BoxFit fit;
  final bool compact;

  const ExerciseMedia({
    super.key,
    required this.exerciseName,
    this.localAsset,
    this.movementPattern,
    this.fit = BoxFit.contain,
    this.compact = false,
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
    _future = _resolveExerciseMedia(widget.exerciseName);
    _profileFuture = ProfileService(client).currentProfile();
  }

  @override
  void didUpdateWidget(covariant ExerciseMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exerciseName != widget.exerciseName) {
      _future = _resolveExerciseMedia(widget.exerciseName);
    }
  }

  Future<OnlineExercise?> _resolveExerciseMedia(String exerciseName) async {
    final direct = await _repository.fetchByName(exerciseName);
    if (_hasRenderableImage(direct)) return direct;

    // A canonical LeanIt/Supabase record may intentionally own the exercise
    // metadata while its reviewed image is still empty. In that case, use only
    // an explicit curated source alias for reference media rather than letting
    // the blank canonical row hide an existing licensed demonstration.
    for (final alias in ExerciseCuration.aliasesFor(exerciseName)) {
      final candidate = await _repository.fetchByName(alias);
      if (_hasRenderableImage(candidate)) return candidate;
    }

    return direct;
  }

  bool _hasRenderableImage(OnlineExercise? exercise) {
    if (exercise == null) return false;
    return exercise.hasApprovedGenericImage ||
        exercise.hasReferenceGenericImage ||
        exercise.hasReviewedMaleImage ||
        exercise.hasReviewedFemaleImage;
  }

  Widget _photoPending() {
    return Container(
      color: const Color(0xFFF2F6F1),
      padding: EdgeInsets.all(widget.compact ? 6 : 18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_camera_back_outlined,
            size: widget.compact ? 24 : 54,
            color: const Color(0xFF2F7D5C),
          ),
          SizedBox(height: widget.compact ? 4 : 10),
          Text(
            widget.exerciseName,
            textAlign: TextAlign.center,
            maxLines: widget.compact ? 2 : 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: widget.compact ? 10 : 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF153B2F),
            ),
          ),
          if (!widget.compact) ...[
            const SizedBox(height: 6),
            const Text(
              'Reviewed LeanIt photo demonstration is being prepared.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: Color(0xFF718078),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fallback() {
    final asset = widget.localAsset;
    if (asset != null && asset.isNotEmpty) {
      return Image.asset(
        asset,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => _photoPending(),
      );
    }
    return _photoPending();
  }

  Widget _loadingPhoto() {
    return Container(
      color: const Color(0xFFF7F9F5),
      alignment: Alignment.center,
      child: SizedBox(
        width: widget.compact ? 18 : 30,
        height: widget.compact ? 18 : 30,
        child: const CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );
  }

  Widget _cachedPhoto(String imagePath) {
    final imageUrl = _repository.publicImageUrl(imagePath);
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: widget.fit,
      fadeInDuration: const Duration(milliseconds: 120),
      placeholder: (_, __) => _loadingPhoto(),
      errorWidget: (_, __, ___) => _fallback(),
    );
  }

  Widget _referencePhoto(String imagePath) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _cachedPhoto(imagePath),
        Positioned(
          left: widget.compact ? 4 : 10,
          right: widget.compact ? 4 : 10,
          bottom: widget.compact ? 4 : 10,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 5 : 9,
              vertical: widget.compact ? 3 : 6,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(widget.compact ? 6 : 10),
            ),
            child: Text(
              widget.compact
                  ? 'REFERENCE'
                  : 'REFERENCE IMAGE • TECHNIQUE REVIEW PENDING',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: widget.compact ? 8 : 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Object?>>(
      future: Future.wait<Object?>([_future, _profileFuture]),
      builder: (context, snapshot) {
        final values = snapshot.data;
        final online = values != null && values.isNotEmpty
            ? values[0] as OnlineExercise?
            : null;
        final profile = values != null && values.length > 1
            ? values[1] as LeanEatProfile?
            : null;

        final reviewedPath =
            online?.reviewedImageForSex(profile?.preferredVisualSex);
        if (reviewedPath != null && reviewedPath.isNotEmpty) {
          return _cachedPhoto(reviewedPath);
        }

        final referencePath = online?.hasReferenceGenericImage == true
            ? online?.imagePath
            : null;
        if (referencePath != null && referencePath.isNotEmpty) {
          return _referencePhoto(referencePath);
        }

        return _fallback();
      },
    );
  }
}
