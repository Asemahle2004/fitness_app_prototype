import 'package:flutter/material.dart';

/// Lightweight built-in movement guide used when a reviewed exercise image or
/// video has not been uploaded yet.
///
/// This is intentionally an instructional diagram, not a claim that the exact
/// drawing is a clinician-validated technique image. It guarantees that every
/// exercise has a START -> FINISH visual while the reviewed media library grows.
class MovementVisual extends StatelessWidget {
  final String exerciseName;
  final String? movementPattern;
  final bool compact;

  const MovementVisual({
    super.key,
    required this.exerciseName,
    this.movementPattern,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = '$exerciseName ${movementPattern ?? ''}'.toLowerCase();

    return Container(
      color: const Color(0xFFF8FCFD),
      padding: EdgeInsets.all(compact ? 6 : 12),
      child: Column(
        children: [
          if (!compact)
            Row(
              children: [
                const Icon(
                  Icons.accessibility_new,
                  size: 18,
                  color: Color(0xFF176B87),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$exerciseName movement guide',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF486581),
                    ),
                  ),
                ),
              ],
            ),
          if (!compact) const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _PosePanel(
                    label: 'START',
                    pose: _PoseKind.fromText(text),
                    finish: false,
                    compact: compact,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 2 : 8),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: compact ? 14 : 26,
                    color: const Color(0xFF176B87),
                  ),
                ),
                Expanded(
                  child: _PosePanel(
                    label: 'FINISH',
                    pose: _PoseKind.fromText(text),
                    finish: true,
                    compact: compact,
                  ),
                ),
              ],
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 6),
            const Text(
              'Use the written instructions below for the full technique cues.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Color(0xFF829AB1)),
            ),
          ],
        ],
      ),
    );
  }
}

class _PosePanel extends StatelessWidget {
  final String label;
  final _PoseKind pose;
  final bool finish;
  final bool compact;

  const _PosePanel({
    required this.label,
    required this.pose,
    required this.finish,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 8 : 14),
        border: Border.all(color: const Color(0xFFD9E2EC)),
      ),
      padding: EdgeInsets.all(compact ? 2 : 7),
      child: Column(
        children: [
          if (!compact)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F4F8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF176B87),
                  ),
                ),
              ),
            ),
          Expanded(
            child: CustomPaint(
              painter: _PosePainter(pose: pose, finish: finish),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

enum _PoseKind {
  standing,
  squat,
  lunge,
  hinge,
  push,
  pull,
  overhead,
  plank,
  run,
  bridge,
  clamshell,
  sideLegRaise,
  straightLegRaise,
  shortArcQuad,
  coreFloor,
  mobility;

  static _PoseKind fromText(String text) {
    if (text.contains('clamshell')) return _PoseKind.clamshell;
    if (text.contains('side-lying hip') || text.contains('side lying hip')) {
      return _PoseKind.sideLegRaise;
    }
    if (text.contains('straight leg raise')) return _PoseKind.straightLegRaise;
    if (text.contains('short arc quad')) return _PoseKind.shortArcQuad;
    if (text.contains('glute bridge') || text.contains('hip bridge')) {
      return _PoseKind.bridge;
    }
    if (text.contains('plank')) return _PoseKind.plank;
    if (text.contains('dead bug') || text.contains('bird dog') || text.contains('core')) {
      return _PoseKind.coreFloor;
    }
    if (text.contains('run') ||
        text.contains('walk') ||
        text.contains('sprint') ||
        text.contains('cardio')) {
      return _PoseKind.run;
    }
    if (text.contains('lunge') || text.contains('split squat')) {
      return _PoseKind.lunge;
    }
    if (text.contains('squat') || text.contains('leg press')) {
      return _PoseKind.squat;
    }
    if (text.contains('deadlift') || text.contains('hinge') || text.contains('good morning')) {
      return _PoseKind.hinge;
    }
    if (text.contains('shoulder') || text.contains('overhead')) {
      return _PoseKind.overhead;
    }
    if (text.contains('row') ||
        text.contains('pulldown') ||
        text.contains('pull') ||
        text.contains('curl')) {
      return _PoseKind.pull;
    }
    if (text.contains('press') ||
        text.contains('push-up') ||
        text.contains('push up') ||
        text.contains('triceps')) {
      return _PoseKind.push;
    }
    if (text.contains('mobility') || text.contains('stretch')) {
      return _PoseKind.mobility;
    }
    return _PoseKind.standing;
  }
}

class _PosePainter extends CustomPainter {
  final _PoseKind pose;
  final bool finish;

  const _PosePainter({required this.pose, required this.finish});

  static const Color _skin = Color(0xFF6E4129);
  static const Color _shirt = Color(0xFF102A43);
  static const Color _shorts = Color(0xFF176B87);
  static const Color _guide = Color(0xFF9FB3C8);

  @override
  void paint(Canvas canvas, Size size) {
    final ground = Paint()
      ..color = const Color(0xFFD9E2EC)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.88),
      Offset(size.width * 0.92, size.height * 0.88),
      ground,
    );

    switch (pose) {
      case _PoseKind.plank:
        _drawPlank(canvas, size);
        break;
      case _PoseKind.bridge:
        _drawBridge(canvas, size);
        break;
      case _PoseKind.clamshell:
        _drawClamshell(canvas, size);
        break;
      case _PoseKind.sideLegRaise:
        _drawSideLegRaise(canvas, size);
        break;
      case _PoseKind.straightLegRaise:
        _drawStraightLegRaise(canvas, size);
        break;
      case _PoseKind.shortArcQuad:
        _drawShortArcQuad(canvas, size);
        break;
      case _PoseKind.coreFloor:
        _drawCoreFloor(canvas, size);
        break;
      case _PoseKind.run:
        _drawRunner(canvas, size);
        break;
      default:
        _drawStanding(canvas, size);
    }
  }

  void _line(Canvas canvas, Offset a, Offset b, Color color, double width) {
    canvas.drawLine(
      a,
      b,
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  void _head(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(center, radius, Paint()..color = _skin);
  }

  void _joint(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(center, radius, Paint()..color = _skin);
  }

  void _drawStanding(Canvas canvas, Size s) {
    final cx = s.width * 0.50;
    double headY = s.height * 0.18;
    double shoulderY = s.height * 0.33;
    double hipY = s.height * 0.56;

    if (pose == _PoseKind.squat && finish) {
      headY += s.height * 0.16;
      shoulderY += s.height * 0.16;
      hipY += s.height * 0.13;
    }
    if (pose == _PoseKind.hinge && finish) {
      headY += s.height * 0.20;
      shoulderY += s.height * 0.16;
    }

    final head = Offset(cx, headY);
    final shoulder = Offset(cx, shoulderY);
    final hip = Offset(cx, hipY);
    _head(canvas, head, s.shortestSide * 0.055);
    _line(canvas, shoulder, hip, _shirt, s.shortestSide * 0.075);

    Offset leftHand;
    Offset rightHand;
    if (pose == _PoseKind.overhead && finish) {
      leftHand = Offset(cx - s.width * 0.18, s.height * 0.12);
      rightHand = Offset(cx + s.width * 0.18, s.height * 0.12);
    } else if (pose == _PoseKind.pull && finish) {
      leftHand = Offset(cx - s.width * 0.19, shoulderY + s.height * 0.02);
      rightHand = Offset(cx + s.width * 0.19, shoulderY + s.height * 0.02);
    } else if (pose == _PoseKind.push && finish) {
      leftHand = Offset(cx - s.width * 0.25, shoulderY - s.height * 0.02);
      rightHand = Offset(cx + s.width * 0.25, shoulderY - s.height * 0.02);
    } else if (pose == _PoseKind.mobility && finish) {
      leftHand = Offset(cx - s.width * 0.12, s.height * 0.10);
      rightHand = Offset(cx + s.width * 0.22, shoulderY + s.height * 0.14);
    } else {
      leftHand = Offset(cx - s.width * 0.17, shoulderY + s.height * 0.20);
      rightHand = Offset(cx + s.width * 0.17, shoulderY + s.height * 0.20);
    }

    _line(canvas, shoulder, leftHand, _skin, s.shortestSide * 0.035);
    _line(canvas, shoulder, rightHand, _skin, s.shortestSide * 0.035);
    _joint(canvas, leftHand, s.shortestSide * 0.018);
    _joint(canvas, rightHand, s.shortestSide * 0.018);

    if (pose == _PoseKind.squat && finish) {
      final lk = Offset(cx - s.width * 0.20, s.height * 0.72);
      final rk = Offset(cx + s.width * 0.20, s.height * 0.72);
      final lf = Offset(cx - s.width * 0.28, s.height * 0.86);
      final rf = Offset(cx + s.width * 0.28, s.height * 0.86);
      _line(canvas, hip, lk, _shorts, s.shortestSide * 0.05);
      _line(canvas, hip, rk, _shorts, s.shortestSide * 0.05);
      _line(canvas, lk, lf, _skin, s.shortestSide * 0.04);
      _line(canvas, rk, rf, _skin, s.shortestSide * 0.04);
    } else if (pose == _PoseKind.lunge && finish) {
      final lk = Offset(cx - s.width * 0.22, s.height * 0.72);
      final rk = Offset(cx + s.width * 0.15, s.height * 0.72);
      final lf = Offset(cx - s.width * 0.30, s.height * 0.86);
      final rf = Offset(cx + s.width * 0.35, s.height * 0.86);
      _line(canvas, hip, lk, _shorts, s.shortestSide * 0.05);
      _line(canvas, hip, rk, _shorts, s.shortestSide * 0.05);
      _line(canvas, lk, lf, _skin, s.shortestSide * 0.04);
      _line(canvas, rk, rf, _skin, s.shortestSide * 0.04);
    } else {
      final lk = Offset(cx - s.width * 0.10, s.height * 0.72);
      final rk = Offset(cx + s.width * 0.10, s.height * 0.72);
      final lf = Offset(cx - s.width * 0.12, s.height * 0.86);
      final rf = Offset(cx + s.width * 0.12, s.height * 0.86);
      _line(canvas, hip, lk, _shorts, s.shortestSide * 0.05);
      _line(canvas, hip, rk, _shorts, s.shortestSide * 0.05);
      _line(canvas, lk, lf, _skin, s.shortestSide * 0.04);
      _line(canvas, rk, rf, _skin, s.shortestSide * 0.04);
    }
  }

  void _drawPlank(Canvas canvas, Size s) {
    final head = Offset(s.width * 0.20, s.height * 0.48);
    final shoulder = Offset(s.width * 0.32, s.height * 0.55);
    final hip = Offset(s.width * 0.62, s.height * 0.57);
    final feet = Offset(s.width * 0.86, s.height * 0.72);
    _head(canvas, head, s.shortestSide * 0.05);
    _line(canvas, shoulder, hip, _shirt, s.shortestSide * 0.075);
    _line(canvas, hip, feet, _shorts, s.shortestSide * 0.05);
    _line(
      canvas,
      shoulder,
      Offset(s.width * 0.28, s.height * 0.76),
      _skin,
      s.shortestSide * 0.04,
    );
    _line(
      canvas,
      Offset(s.width * 0.28, s.height * 0.76),
      Offset(s.width * 0.42, s.height * 0.76),
      _skin,
      s.shortestSide * 0.04,
    );
  }

  void _drawBridge(Canvas canvas, Size s) {
    final head = Offset(s.width * 0.16, s.height * 0.70);
    final shoulder = Offset(s.width * 0.30, s.height * 0.72);
    final hip = Offset(s.width * 0.55, finish ? s.height * 0.48 : s.height * 0.72);
    final knee = Offset(s.width * 0.72, s.height * 0.58);
    final foot = Offset(s.width * 0.84, s.height * 0.82);
    _head(canvas, head, s.shortestSide * 0.05);
    _line(canvas, shoulder, hip, _shirt, s.shortestSide * 0.07);
    _line(canvas, hip, knee, _shorts, s.shortestSide * 0.05);
    _line(canvas, knee, foot, _skin, s.shortestSide * 0.04);
  }

  void _drawClamshell(Canvas canvas, Size s) {
    final head = Offset(s.width * 0.18, s.height * 0.48);
    final shoulder = Offset(s.width * 0.31, s.height * 0.58);
    final hip = Offset(s.width * 0.56, s.height * 0.64);
    final bottomKnee = Offset(s.width * 0.72, s.height * 0.72);
    final feet = Offset(s.width * 0.84, s.height * 0.80);
    final topKnee = finish
        ? Offset(s.width * 0.68, s.height * 0.48)
        : bottomKnee;
    _head(canvas, head, s.shortestSide * 0.05);
    _line(canvas, shoulder, hip, _shirt, s.shortestSide * 0.07);
    _line(canvas, hip, bottomKnee, _shorts, s.shortestSide * 0.045);
    _line(canvas, bottomKnee, feet, _skin, s.shortestSide * 0.035);
    _line(canvas, hip, topKnee, _shorts, s.shortestSide * 0.045);
    _line(canvas, topKnee, feet, _skin, s.shortestSide * 0.035);
  }

  void _drawSideLegRaise(Canvas canvas, Size s) {
    final head = Offset(s.width * 0.17, s.height * 0.55);
    final shoulder = Offset(s.width * 0.31, s.height * 0.62);
    final hip = Offset(s.width * 0.55, s.height * 0.67);
    final bottomFoot = Offset(s.width * 0.86, s.height * 0.78);
    final topFoot = finish
        ? Offset(s.width * 0.83, s.height * 0.43)
        : Offset(s.width * 0.86, s.height * 0.72);
    _head(canvas, head, s.shortestSide * 0.05);
    _line(canvas, shoulder, hip, _shirt, s.shortestSide * 0.07);
    _line(canvas, hip, bottomFoot, _skin, s.shortestSide * 0.04);
    _line(canvas, hip, topFoot, _shorts, s.shortestSide * 0.045);
  }

  void _drawStraightLegRaise(Canvas canvas, Size s) {
    final head = Offset(s.width * 0.16, s.height * 0.69);
    final shoulder = Offset(s.width * 0.30, s.height * 0.72);
    final hip = Offset(s.width * 0.52, s.height * 0.72);
    final foot = finish
        ? Offset(s.width * 0.83, s.height * 0.42)
        : Offset(s.width * 0.84, s.height * 0.76);
    final bentKnee = Offset(s.width * 0.67, s.height * 0.58);
    final bentFoot = Offset(s.width * 0.79, s.height * 0.80);
    _head(canvas, head, s.shortestSide * 0.05);
    _line(canvas, shoulder, hip, _shirt, s.shortestSide * 0.07);
    _line(canvas, hip, foot, _shorts, s.shortestSide * 0.045);
    _line(canvas, hip, bentKnee, _shorts, s.shortestSide * 0.045);
    _line(canvas, bentKnee, bentFoot, _skin, s.shortestSide * 0.035);
  }

  void _drawShortArcQuad(Canvas canvas, Size s) {
    final head = Offset(s.width * 0.15, s.height * 0.70);
    final shoulder = Offset(s.width * 0.29, s.height * 0.73);
    final hip = Offset(s.width * 0.51, s.height * 0.73);
    final knee = Offset(s.width * 0.68, s.height * 0.62);
    final foot = finish
        ? Offset(s.width * 0.86, s.height * 0.60)
        : Offset(s.width * 0.80, s.height * 0.80);
    _head(canvas, head, s.shortestSide * 0.05);
    _line(canvas, shoulder, hip, _shirt, s.shortestSide * 0.07);
    _line(canvas, hip, knee, _shorts, s.shortestSide * 0.045);
    _line(canvas, knee, foot, _skin, s.shortestSide * 0.04);
    canvas.drawCircle(
      Offset(s.width * 0.68, s.height * 0.72),
      s.shortestSide * 0.045,
      Paint()..color = _guide,
    );
  }

  void _drawCoreFloor(Canvas canvas, Size s) {
    final head = Offset(s.width * 0.18, s.height * 0.69);
    final shoulder = Offset(s.width * 0.32, s.height * 0.72);
    final hip = Offset(s.width * 0.54, s.height * 0.72);
    final hand = finish
        ? Offset(s.width * 0.42, s.height * 0.38)
        : Offset(s.width * 0.38, s.height * 0.60);
    final foot = finish
        ? Offset(s.width * 0.84, s.height * 0.50)
        : Offset(s.width * 0.76, s.height * 0.78);
    _head(canvas, head, s.shortestSide * 0.05);
    _line(canvas, shoulder, hip, _shirt, s.shortestSide * 0.07);
    _line(canvas, shoulder, hand, _skin, s.shortestSide * 0.035);
    _line(canvas, hip, foot, _shorts, s.shortestSide * 0.045);
  }

  void _drawRunner(Canvas canvas, Size s) {
    final head = Offset(s.width * 0.50, s.height * 0.19);
    final shoulder = Offset(s.width * 0.50, s.height * 0.35);
    final hip = Offset(s.width * 0.50, s.height * 0.57);
    final direction = finish ? -1.0 : 1.0;
    _head(canvas, head, s.shortestSide * 0.055);
    _line(canvas, shoulder, hip, _shirt, s.shortestSide * 0.075);
    _line(
      canvas,
      shoulder,
      Offset(s.width * (0.50 + 0.19 * direction), s.height * 0.46),
      _skin,
      s.shortestSide * 0.035,
    );
    _line(
      canvas,
      shoulder,
      Offset(s.width * (0.50 - 0.18 * direction), s.height * 0.42),
      _skin,
      s.shortestSide * 0.035,
    );
    _line(
      canvas,
      hip,
      Offset(s.width * (0.50 + 0.22 * direction), s.height * 0.82),
      _shorts,
      s.shortestSide * 0.05,
    );
    _line(
      canvas,
      hip,
      Offset(s.width * (0.50 - 0.20 * direction), s.height * 0.76),
      _skin,
      s.shortestSide * 0.04,
    );
  }

  @override
  bool shouldRepaint(covariant _PosePainter oldDelegate) {
    return oldDelegate.pose != pose || oldDelegate.finish != finish;
  }
}
