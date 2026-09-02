import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'exercise_curation.dart';
import 'exercise_repository.dart';
import 'musclewiki_media_service.dart';
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
  late final MuscleWikiMediaService _provider;
  late Future<_ExerciseMediaBundle> _future;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _repository = ExerciseRepository(client);
    _provider = MuscleWikiMediaService(client);
    _future = _load(widget.exerciseName);
  }

  @override
  void didUpdateWidget(covariant ExerciseMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exerciseName != widget.exerciseName) {
      _future = _load(widget.exerciseName);
    }
  }

  Future<_ExerciseMediaBundle> _load(String exerciseName) async {
    final profile = await ProfileService(Supabase.instance.client).currentProfile();
    final providerMedia = await _provider.resolve(
      exerciseName: exerciseName,
      sex: profile?.preferredVisualSex,
    );
    final legacy = await _resolveLegacyMedia(exerciseName);
    return _ExerciseMediaBundle(
      profile: profile,
      provider: providerMedia,
      legacy: legacy,
    );
  }

  Future<OnlineExercise?> _resolveLegacyMedia(String exerciseName) async {
    final direct = await _repository.fetchByName(exerciseName);
    if (_hasRenderableImage(direct)) return direct;
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
            Icons.fitness_center_outlined,
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
              'Standardised male/female demonstration mapping is pending for this exercise.',
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

  Widget _providerPhoto(String url) {
    // Provider URLs contain short-lived media credentials. Image.network keeps
    // them out of the app's persistent disk cache; never store these URLs in
    // SharedPreferences, Supabase or analytics.
    return Image.network(
      url,
      fit: widget.fit,
      gaplessPlayback: true,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _loadingPhoto(),
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _legacyCachedPhoto(String imagePath) {
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
        _legacyCachedPhoto(imagePath),
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
                  ? 'LEGACY'
                  : 'LEGACY REFERENCE • UNIFIED PROVIDER MAPPING PENDING',
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

  Widget _legacy(_ExerciseMediaBundle bundle) {
    final online = bundle.legacy;
    final reviewedPath =
        online?.reviewedImageForSex(bundle.profile?.preferredVisualSex);
    if (reviewedPath != null && reviewedPath.isNotEmpty) {
      return _legacyCachedPhoto(reviewedPath);
    }
    final referencePath =
        online?.hasReferenceGenericImage == true ? online?.imagePath : null;
    if (referencePath != null && referencePath.isNotEmpty) {
      return _referencePhoto(referencePath);
    }
    return _fallback();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ExerciseMediaBundle>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadingPhoto();
        }
        final bundle = snapshot.data;
        if (bundle == null) return _fallback();
        final providerImage = bundle.provider.imageUrl;
        if (bundle.provider.available &&
            providerImage != null &&
            providerImage.isNotEmpty) {
          return _providerPhoto(providerImage);
        }
        return _legacy(bundle);
      },
    );
  }
}

class _ExerciseMediaBundle {
  final LeanEatProfile? profile;
  final MuscleWikiMediaResult provider;
  final OnlineExercise? legacy;

  const _ExerciseMediaBundle({
    required this.profile,
    required this.provider,
    required this.legacy,
  });
}
