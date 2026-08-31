import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final Map<String, Future<Uint8List>> _imageDownloads = {};

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
      _imageDownloads.clear();
    }
  }

  Future<Uint8List> _imageBytes(String path) {
    return _imageDownloads.putIfAbsent(
      path,
      () => _repository.downloadImage(path),
    );
  }

  bool _isRemoteUrl(String value) {
    final lower = value.toLowerCase();
    return lower.startsWith('https://') || lower.startsWith('http://');
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
              'Reviewed LeanEat photo demonstration is being prepared.',
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

  Widget _remotePhoto(String imageUrl) {
    return Image.network(
      imageUrl,
      fit: widget.fit,
      gaplessPlayback: true,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _loadingPhoto();
      },
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _reviewedPhoto(String imagePath) {
    if (_isRemoteUrl(imagePath)) {
      return _remotePhoto(imagePath);
    }

    return FutureBuilder<Uint8List>(
      future: _imageBytes(imagePath),
      builder: (context, imageSnapshot) {
        if (imageSnapshot.hasData && imageSnapshot.data!.isNotEmpty) {
          return Image.memory(
            imageSnapshot.data!,
            fit: widget.fit,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => _fallback(),
          );
        }
        if (imageSnapshot.hasError) {
          return _fallback();
        }
        return _loadingPhoto();
      },
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
        final imagePath = online?.reviewedImageForSex(profile?.preferredVisualSex);
        if (imagePath != null && imagePath.isNotEmpty) {
          return _reviewedPhoto(imagePath);
        }
        return _fallback();
      },
    );
  }
}
