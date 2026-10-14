import 'dart:math' as math;

import 'package:flutter/material.dart';

const heroPhoto = 'assets/images/home backround.png';

/// The same road silhouette used to cut the home hero.
class HeroEdgeClipper extends CustomClipper<Path> {
  const HeroEdgeClipper();

  @override
  Path getClip(Size size) => HeroEdge(size).clip();

  @override
  bool shouldReclip(covariant HeroEdgeClipper oldClipper) => false;
}

class HeroEdge {
  HeroEdge(this.size);

  final Size size;

  Path road({required bool rtl}) {
    final path = _forward();
    if (!rtl) return path;
    final mirror = Matrix4.identity()
      ..translateByDouble(size.width, 0, 0, 1)
      ..scaleByDouble(-1, 1, 1, 1);
    return path.transform(mirror.storage);
  }

  Path clip() {
    final metric = road(rtl: false).computeMetrics().single;
    final clip = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0);
    final end = metric.getTangentForOffset(math.max(0, metric.length - 0.2))!.position;
    clip.lineTo(end.dx, end.dy);
    for (var distance = metric.length - 0.2; distance >= 0; distance -= 5) {
      final point = metric.getTangentForOffset(distance.clamp(0, metric.length).toDouble());
      if (point == null) continue;
      clip.lineTo(point.position.dx, point.position.dy);
    }
    clip.close();
    return clip;
  }

  Path _forward() {
    final h = size.height;
    final w = size.width;
    final lift = w >= 700 ? 1.0 : 0.65;
    double y(double fromBottom) => h - fromBottom * lift;
    return Path()
      ..moveTo(0, y(48))
      ..cubicTo(w * 0.08, y(40), w * 0.14, y(88), w * 0.24, y(76))
      ..cubicTo(w * 0.34, y(64), w * 0.42, y(36), w * 0.52, y(42))
      ..cubicTo(w * 0.62, y(48), w * 0.7, y(84), w * 0.8, y(72))
      ..cubicTo(w * 0.9, y(60), w * 0.96, y(38), w, y(50));
  }
}

/// The road stroke along the hero edge, without the moving truck.
class HeroRoadStrokePainter extends CustomPainter {
  const HeroRoadStrokePainter({required this.rtl});

  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 2 || size.height < 2) return;
    final road = HeroEdge(size).road(rtl: rtl);
    canvas.drawPath(
      road,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round
        ..color = const Color(0x59000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawPath(
      road,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 13
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xF0121822),
    );
    canvas.drawPath(
      road,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.15
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xB3FFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant HeroRoadStrokePainter oldDelegate) => oldDelegate.rtl != rtl;
}
