import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'musclewiki_media_service.dart';
import 'profile_service.dart';

/// LeanIt exercise demonstration surface.
///
/// Compact instances are intentionally network-free. The Exercise Library can
/// render hundreds of rows, and starting profile/database/provider requests for
/// every visible thumbnail caused severe jank and Android ANRs on real phones.
/// Full demonstration media is resolved only on a detail/workout surface.
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
  Future<_ExerciseMediaBundle>? _future;

  @override
  void initState() {
    super.initState();
    if (!widget.compact) {
      _future = _load(widget.exerciseName);
    }
  }

  @override
  void didUpdateWidget(covariant ExerciseMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.compact) {
      _future = null;
      return;
    }
    if (oldWidget.exerciseName != widget.exerciseName || oldWidget.compact) {
      _future = _load(widget.exerciseName);
    }
  }

  Future<_ExerciseMediaBundle> _load(String exerciseName) async {
    final client = Supabase.instance.client;
    LeanEatProfile? profile;
    try {
      profile = await ProfileService(client).currentProfile();
    } catch (_) {
      // Media may still resolve with the neutral/male default.
    }

    final provider = await MuscleWikiMediaService(client).resolve(
      exerciseName: exerciseName,
      sex: profile?.preferredVisualSex,
    );
    return _ExerciseMediaBundle(profile: profile, provider: provider);
  }

  Widget _placeholder({bool loading = false}) {
    final asset = widget.localAsset;
    if (asset != null && asset.trim().isNotEmpty) {
      return Image.asset(
        asset,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => _placeholderWithoutAsset(loading: loading),
      );
    }
    return _placeholderWithoutAsset(loading: loading);
  }

  Widget _placeholderWithoutAsset({bool loading = false}) {
    return Container(
      color: const Color(0xFFF2F6F1),
      padding: EdgeInsets.all(widget.compact ? 6 : 18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading && !widget.compact)
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          else
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
          if (!widget.compact && !loading) ...[
            const SizedBox(height: 6),
            const Text(
              'Demonstration media is unavailable offline or still awaiting the unified provider mapping.',
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

  Widget _providerPhoto(String url) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          url,
          fit: widget.fit,
          gaplessPlayback: true,
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : _placeholder(loading: true),
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
        Positioned(
          left: 10,
          right: 10,
          bottom: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Exercise data and videos provided by MuscleWiki.com',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Critical performance rule: hundreds of compact cards must never create
    // hundreds of Supabase/provider requests simply because the user scrolls.
    if (widget.compact) return _placeholder();

    final future = _future ??= _load(widget.exerciseName);
    return FutureBuilder<_ExerciseMediaBundle>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _placeholder(loading: true);
        }
        final provider = snapshot.data?.provider;
        final imageUrl = provider?.imageUrl;
        if (provider?.available == true &&
            imageUrl != null &&
            imageUrl.trim().isNotEmpty) {
          return _providerPhoto(imageUrl);
        }
        return _placeholder();
      },
    );
  }
}

class _ExerciseMediaBundle {
  final LeanEatProfile? profile;
  final MuscleWikiMediaResult provider;

  const _ExerciseMediaBundle({
    required this.profile,
    required this.provider,
  });
}
