import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'donut_geometry.dart';
import 'donut_segment.dart';

/// Paints a donut chart. Used internally by [DonutChart], but exposed so it
/// can be reused in custom layouts.
class DonutPainter extends CustomPainter {
  /// Creates a painter for [segments] laid out along [arcs].
  DonutPainter({
    required this.segments,
    required this.arcs,
    required this.thickness,
    required this.startAngle,
    this.progress = 1,
    this.activeIndex,
    this.expansion = 0,
    this.trackColor,
    this.roundedEnds = false,
  }) : assert(segments.length == arcs.length);

  /// The segments to paint.
  final List<DonutSegment> segments;

  /// The arcs, one per segment (see [computeArcs]).
  final List<SegmentArc> arcs;

  /// Thickness of the ring.
  final double thickness;

  /// Angle in radians where the ring starts; used for the reveal animation.
  final double startAngle;

  /// Reveal progress from 0 (nothing drawn) to 1 (full ring).
  final double progress;

  /// The highlighted segment, drawn [expansion] pixels thicker.
  final int? activeIndex;

  /// How far the highlighted segment grows outward.
  final double expansion;

  /// Optional background ring color, drawn under the segments.
  final Color? trackColor;

  /// Whether segment ends are rounded.
  final bool roundedEnds;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = DonutLayout.of(
      size,
      thickness: thickness,
      expansion: expansion,
    );
    if (layout.outerRadius <= 0) return;
    final center = layout.center;
    final baseRadius = layout.outerRadius - thickness / 2;

    final track = trackColor;
    if (track != null) {
      canvas.drawCircle(
        center,
        baseRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = thickness
          ..color = track,
      );
    }

    final visibleEnd = startAngle + 2 * math.pi * progress.clamp(0.0, 1.0);
    for (var i = 0; i < arcs.length; i++) {
      final arc = arcs[i];
      if (arc.sweep <= 0) continue;
      final sweep = (visibleEnd - arc.start).clamp(0.0, arc.sweep);
      if (sweep <= 0) continue;

      final active = i == activeIndex;
      final width = active ? thickness + expansion : thickness;
      final radius = baseRadius + (active ? expansion / 2 : 0);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = roundedEnds ? StrokeCap.round : StrokeCap.butt
        ..color = segments[i].color;

      var drawStart = arc.start;
      var drawSweep = sweep;
      if (roundedEnds) {
        // Round caps stick out by half the stroke width at each end, so
        // pull the arc in to keep the caps inside the segment's own range.
        final cap = (width / 2) / radius;
        if (drawSweep > 2 * cap) {
          drawStart += cap;
          drawSweep -= 2 * cap;
        } else {
          drawStart += drawSweep / 2;
          drawSweep = 0.0001;
        }
      }

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        drawStart,
        drawSweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(DonutPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.arcs != arcs ||
        oldDelegate.thickness != thickness ||
        oldDelegate.startAngle != startAngle ||
        oldDelegate.progress != progress ||
        oldDelegate.activeIndex != activeIndex ||
        oldDelegate.expansion != expansion ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.roundedEnds != roundedEnds;
  }
}
