import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

/// The angular range (in radians) that a single segment occupies.
class SegmentArc {
  /// Creates an arc starting at [start] and sweeping [sweep] radians clockwise.
  const SegmentArc(this.start, this.sweep);

  /// Start angle in radians. 0 points to the right, angles grow clockwise.
  final double start;

  /// Sweep in radians. Zero means the segment is not visible.
  final double sweep;

  /// End angle in radians.
  double get end => start + sweep;

  @override
  String toString() => 'SegmentArc(start: $start, sweep: $sweep)';
}

/// Resolved geometry of a donut drawn inside a box of a given size.
class DonutLayout {
  /// Computes the layout for a donut of [thickness] painted in [size].
  ///
  /// [expansion] is the extra room reserved around the ring so that a
  /// highlighted segment can grow outward without being clipped.
  DonutLayout.of(Size size, {required this.thickness, double expansion = 0})
      : center = size.center(Offset.zero),
        outerRadius = math.max(
          0.0,
          math.min(size.width, size.height) / 2 - expansion,
        );

  /// Center of the donut.
  final Offset center;

  /// Outer radius of the (non-highlighted) ring.
  final double outerRadius;

  /// Thickness of the ring.
  final double thickness;

  /// Inner radius of the ring (the radius of the hole).
  double get innerRadius => math.max(0.0, outerRadius - thickness);
}

/// Splits a full circle into arcs proportional to [values].
///
/// Non-finite, zero and negative values produce zero-sweep arcs so that the
/// returned list always has the same length (and indices) as [values].
/// [gap] is the empty space in radians between neighbouring visible
/// segments. No gap is applied when fewer than two segments are visible.
List<SegmentArc> computeArcs(
  List<double> values, {
  double startAngle = -math.pi / 2,
  double gap = 0,
}) {
  final cleaned = [
    for (final v in values) (v.isFinite && v > 0) ? v : 0.0,
  ];
  final total = cleaned.fold<double>(0, (a, b) => a + b);
  if (total <= 0) {
    return List.filled(cleaned.length, SegmentArc(startAngle, 0));
  }

  final visible = cleaned.where((v) => v > 0).length;
  final effectiveGap = visible > 1 ? math.max(0.0, gap) : 0.0;
  final available = math.max(0.0, 2 * math.pi - effectiveGap * visible);

  var cursor = startAngle;
  final arcs = <SegmentArc>[];
  for (final v in cleaned) {
    if (v == 0) {
      arcs.add(SegmentArc(cursor, 0));
      continue;
    }
    final sweep = available * v / total;
    arcs.add(SegmentArc(cursor + effectiveGap / 2, sweep));
    cursor += sweep + effectiveGap;
  }
  return arcs;
}

/// Returns the share of each value in percent (0–100).
///
/// Non-finite, zero and negative values count as 0. If the total is 0,
/// every entry is 0.
List<double> percentagesOf(List<double> values) {
  final cleaned = [
    for (final v in values) (v.isFinite && v > 0) ? v : 0.0,
  ];
  final total = cleaned.fold<double>(0, (a, b) => a + b);
  if (total <= 0) return List.filled(cleaned.length, 0.0);
  return [for (final v in cleaned) v / total * 100];
}

/// Returns the index of the segment under [position], or `null` if the
/// position is in the hole, outside the ring, or inside a gap.
///
/// [tolerance] widens the outer edge, which is useful when a highlighted
/// segment is drawn larger than the others.
int? hitTestDonut({
  required Offset position,
  required DonutLayout layout,
  required List<SegmentArc> arcs,
  double tolerance = 0,
}) {
  final delta = position - layout.center;
  final distance = delta.distance;
  if (distance > layout.outerRadius + tolerance ||
      distance < layout.innerRadius) {
    return null;
  }
  final angle = math.atan2(delta.dy, delta.dx);
  for (var i = 0; i < arcs.length; i++) {
    final arc = arcs[i];
    if (arc.sweep <= 0) continue;
    // Dart's % is Euclidean, so the result is always in [0, 2π).
    final relative = (angle - arc.start) % (2 * math.pi);
    if (relative <= arc.sweep) return i;
  }
  return null;
}
