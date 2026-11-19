import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_donut/interactive_donut.dart';

const _segments = [
  DonutSegment(value: 1, color: Colors.indigo, label: 'A'),
  DonutSegment(value: 1, color: Colors.teal, label: 'B'),
];

Widget _app(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('renders and shows center content', (tester) async {
    await tester.pumpWidget(_app(
      DonutChart(
        size: 200,
        segments: _segments,
        centerBuilder: (context, i) => Text(i == null ? 'none' : 'active $i'),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(DonutChart), findsOneWidget);
    expect(find.text('none'), findsOneWidget);
    expect(tester.getSize(find.byType(DonutChart)), const Size(200, 200));
  });

  testWidgets('tapping a segment selects it and tapping again clears it',
      (tester) async {
    final taps = <int>[];
    final selections = <int?>[];

    await tester.pumpWidget(_app(
      DonutChart(
        size: 200,
        segments: _segments,
        animationDuration: Duration.zero,
        onSegmentTap: taps.add,
        onSelectionChanged: selections.add,
        centerBuilder: (context, i) => Text(i == null ? 'none' : 'active $i'),
      ),
    ));

    // size 200, expansion 6 -> outer radius 94, inner radius 70.
    final center = tester.getCenter(find.byType(DonutChart));
    const angle = -math.pi / 2 + 0.6; // just right of 12 o'clock -> segment 0
    final onFirst =
        center + Offset(82 * math.cos(angle), 82 * math.sin(angle));

    await tester.tapAt(onFirst);
    await tester.pump();
    expect(taps, [0]);
    expect(selections, [0]);
    expect(find.text('active 0'), findsOneWidget);

    await tester.tapAt(onFirst);
    await tester.pump();
    expect(taps, [0, 0]);
    expect(selections, [0, null]);
    expect(find.text('none'), findsOneWidget);
  });

  testWidgets('tapping the hole clears the selection', (tester) async {
    final selections = <int?>[];
    await tester.pumpWidget(_app(
      DonutChart(
        size: 200,
        segments: _segments,
        selectedIndex: 1,
        animationDuration: Duration.zero,
        onSelectionChanged: selections.add,
      ),
    ));

    await tester.tapAt(tester.getCenter(find.byType(DonutChart)));
    await tester.pump();
    expect(selections, [null]);
  });

  testWidgets('builds a default semantics label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_app(
      const DonutChart(size: 200, segments: _segments),
    ));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(RegExp(r'Donut chart: A 50\.0%, B 50\.0%')),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('legend shows labels and percentages and reports taps',
      (tester) async {
    final tapped = <int>[];
    await tester.pumpWidget(_app(
      DonutLegend(segments: _segments, onTap: tapped.add),
    ));

    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('50.0%'), findsNWidgets(2));

    await tester.tap(find.text('B'));
    expect(tapped, [1]);
  });
}
