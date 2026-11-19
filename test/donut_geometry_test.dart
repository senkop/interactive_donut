import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_donut/interactive_donut.dart';

void main() {
  group('computeArcs', () {
    test('splits equal values into equal halves', () {
      final arcs = computeArcs([1, 1]);
      expect(arcs, hasLength(2));
      expect(arcs[0].start, closeTo(-math.pi / 2, 1e-9));
      expect(arcs[0].sweep, closeTo(math.pi, 1e-9));
      expect(arcs[1].start, closeTo(math.pi / 2, 1e-9));
      expect(arcs[1].sweep, closeTo(math.pi, 1e-9));
    });

    test('ignores zero, negative and non-finite values but keeps indices', () {
      final arcs = computeArcs([0, 2, -5, double.nan, 2]);
      expect(arcs, hasLength(5));
      expect(arcs[0].sweep, 0);
      expect(arcs[2].sweep, 0);
      expect(arcs[3].sweep, 0);
      expect(arcs[1].sweep + arcs[4].sweep, closeTo(2 * math.pi, 1e-9));
    });

    test('reserves the requested gap between visible segments', () {
      const gap = 0.1;
      final arcs = computeArcs([1, 2, 3], gap: gap);
      final swept = arcs.fold<double>(0, (sum, a) => sum + a.sweep);
      expect(swept, closeTo(2 * math.pi - 3 * gap, 1e-9));
      expect(arcs[1].start - arcs[0].end, closeTo(gap, 1e-9));
    });

    test('a single visible segment fills the circle without a gap', () {
      final arcs = computeArcs([0, 5], gap: 0.2);
      expect(arcs[1].sweep, closeTo(2 * math.pi, 1e-9));
    });

    test('all-zero values produce empty arcs', () {
      final arcs = computeArcs([0, 0, 0]);
      expect(arcs.every((a) => a.sweep == 0), isTrue);
    });
  });

  group('percentagesOf', () {
    test('returns shares in percent', () {
      expect(percentagesOf([1, 3]), [25, 75]);
    });

    test('returns zeros when the total is zero', () {
      expect(percentagesOf([0, -1]), [0, 0]);
    });
  });

  group('hitTestDonut', () {
    final layout = DonutLayout.of(const Size(200, 200), thickness: 20);
    final arcs = computeArcs([1, 1]); // right half, then left half

    Offset at(double angle, double radius) => Offset(
          100 + radius * math.cos(angle),
          100 + radius * math.sin(angle),
        );

    test('finds the segment under a point on the ring', () {
      expect(
        hitTestDonut(
            position: at(-math.pi / 4, 90), layout: layout, arcs: arcs),
        0,
      );
      expect(
        hitTestDonut(position: at(math.pi, 90), layout: layout, arcs: arcs),
        1,
      );
    });

    test('returns null in the hole and outside the ring', () {
      expect(
        hitTestDonut(
          position: const Offset(100, 100),
          layout: layout,
          arcs: arcs,
        ),
        isNull,
      );
      expect(
        hitTestDonut(
          position: const Offset(199, 199),
          layout: layout,
          arcs: arcs,
        ),
        isNull,
      );
    });

    test('tolerance widens the outer edge', () {
      final outside = at(0, 103);
      expect(
        hitTestDonut(position: outside, layout: layout, arcs: arcs),
        isNull,
      );
      expect(
        hitTestDonut(
          position: outside,
          layout: layout,
          arcs: arcs,
          tolerance: 5,
        ),
        0,
      );
    });

    test('returns null inside a gap', () {
      final gapped = computeArcs([1, 1], gap: 0.4);
      expect(
        hitTestDonut(
          position: at(-math.pi / 2, 90),
          layout: layout,
          arcs: gapped,
        ),
        isNull,
      );
    });
  });
}
