import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'donut_geometry.dart';
import 'donut_painter.dart';
import 'donut_segment.dart';

/// Builds the content shown in the hole of a [DonutChart].
///
/// [activeIndex] is the hovered segment if there is one, otherwise the
/// selected segment, otherwise `null`.
typedef DonutCenterBuilder = Widget Function(
  BuildContext context,
  int? activeIndex,
);

/// An animated, interactive donut chart.
///
/// Segments animate in when the chart first appears and whenever
/// [segments] changes. On desktop and web, hovering a segment highlights it.
/// Tapping a segment selects it, and tapping it again (or tapping
/// outside the ring) clears the selection.
///
/// ```dart
/// DonutChart(
///   size: 220,
///   segments: const [
///     DonutSegment(value: 45, color: Colors.indigo, label: 'Rent'),
///     DonutSegment(value: 30, color: Colors.teal, label: 'Food'),
///     DonutSegment(value: 25, color: Colors.amber, label: 'Fun'),
///   ],
///   centerBuilder: (context, i) => Text(i == null ? 'Total' : '#$i'),
/// )
/// ```
class DonutChart extends StatefulWidget {
  /// Creates a donut chart.
  const DonutChart({
    super.key,
    required this.segments,
    this.size,
    this.thickness = 24,
    this.gapDegrees = 2,
    this.startAngleDegrees = -90,
    this.animationDuration = const Duration(milliseconds: 900),
    this.curve = Curves.easeOutCubic,
    this.highlightExpansion = 6,
    this.trackColor,
    this.roundedEnds = false,
    this.enableHover = true,
    this.enableSelection = true,
    this.selectedIndex,
    this.centerBuilder,
    this.onSegmentTap,
    this.onSelectionChanged,
    this.onHoverChanged,
    this.semanticsLabel,
  })  : assert(thickness > 0),
        assert(gapDegrees >= 0),
        assert(highlightExpansion >= 0);

  /// The slices of the chart, drawn clockwise in order.
  final List<DonutSegment> segments;

  /// Width and height of the chart. When `null`, the chart is a square
  /// sized by its parent, which then must give it a bounded width or height.
  final double? size;

  /// Thickness of the ring in logical pixels.
  final double thickness;

  /// Empty space between neighbouring segments, in degrees.
  final double gapDegrees;

  /// Where the first segment starts, in degrees. -90 is 12 o'clock.
  final double startAngleDegrees;

  /// Duration of the reveal animation. Use [Duration.zero] to disable it.
  final Duration animationDuration;

  /// Curve of the reveal animation.
  final Curve curve;

  /// How many pixels the active (hovered or selected) segment grows outward.
  final double highlightExpansion;

  /// Optional color of a background ring drawn behind the segments.
  final Color? trackColor;

  /// Whether segment ends are rounded.
  final bool roundedEnds;

  /// Whether hovering with a mouse highlights segments.
  final bool enableHover;

  /// Whether tapping a segment selects it.
  final bool enableSelection;

  /// The selected segment.
  ///
  /// The chart starts with this selection and follows it whenever it
  /// changes. Taps still change the selection inside the chart and report it
  /// through [onSelectionChanged]; to fully control it, store that value and
  /// pass it back here.
  final int? selectedIndex;

  /// Builds content shown in the hole of the donut.
  final DonutCenterBuilder? centerBuilder;

  /// Called with the index of a segment when it is tapped.
  final ValueChanged<int>? onSegmentTap;

  /// Called when the selected segment changes. `null` means no selection.
  final ValueChanged<int?>? onSelectionChanged;

  /// Called when the hovered segment changes. `null` means none.
  final ValueChanged<int?>? onHoverChanged;

  /// Accessibility label. Defaults to a summary of labels and percentages.
  final String? semanticsLabel;

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int? _hovered;
  int? _selected;

  static double _rad(double degrees) => degrees * math.pi / 180;

  int? get _active => _hovered ?? _selected;

  @override
  void initState() {
    super.initState();
    _selected = _validIndex(widget.selectedIndex);
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _play();
  }

  @override
  void didUpdateWidget(covariant DonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.animationDuration;
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _selected = _validIndex(widget.selectedIndex);
    }
    if (!listEquals(oldWidget.segments, widget.segments)) {
      _hovered = null;
      _selected = _validIndex(_selected);
      _play();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? _validIndex(int? index) =>
      (index != null && index >= 0 && index < widget.segments.length)
          ? index
          : null;

  void _play() {
    if (widget.animationDuration == Duration.zero) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  void _setHovered(int? index) {
    if (index == _hovered) return;
    setState(() => _hovered = index);
    widget.onHoverChanged?.call(index);
  }

  void _handleTap(int? index) {
    if (index != null) widget.onSegmentTap?.call(index);
    if (!widget.enableSelection) return;
    final next = index == _selected ? null : index;
    if (next == _selected) return;
    setState(() => _selected = next);
    widget.onSelectionChanged?.call(next);
  }

  String _describe() {
    final percents = percentagesOf([for (final s in widget.segments) s.value]);
    final parts = <String>[];
    for (var i = 0; i < widget.segments.length; i++) {
      final label = widget.segments[i].label ?? 'Segment ${i + 1}';
      parts.add('$label ${percents[i].toStringAsFixed(1)}%');
    }
    return 'Donut chart: ${parts.join(', ')}';
  }

  @override
  Widget build(BuildContext context) {
    final startAngle = _rad(widget.startAngleDegrees);
    final arcs = computeArcs(
      [for (final s in widget.segments) s.value],
      startAngle: startAngle,
      gap: _rad(widget.gapDegrees),
    );
    final interactive = widget.enableSelection || widget.onSegmentTap != null;

    Widget chart = LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final layout = DonutLayout.of(
          size,
          thickness: widget.thickness,
          expansion: widget.highlightExpansion,
        );
        int? hit(Offset position) => hitTestDonut(
              position: position,
              layout: layout,
              arcs: arcs,
              tolerance: widget.highlightExpansion,
            );

        return MouseRegion(
          cursor: interactive && _hovered != null
              ? SystemMouseCursors.click
              : MouseCursor.defer,
          onHover: widget.enableHover
              ? (event) => _setHovered(hit(event.localPosition))
              : null,
          onExit: widget.enableHover ? (_) => _setHovered(null) : null,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) => _handleTap(hit(details.localPosition)),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                size: size,
                painter: DonutPainter(
                  segments: widget.segments,
                  arcs: arcs,
                  thickness: widget.thickness,
                  startAngle: startAngle,
                  progress: widget.curve.transform(_controller.value),
                  activeIndex: _active,
                  expansion: widget.highlightExpansion,
                  trackColor: widget.trackColor,
                  roundedEnds: widget.roundedEnds,
                ),
              ),
            ),
          ),
        );
      },
    );

    final centerBuilder = widget.centerBuilder;
    if (centerBuilder != null) {
      chart = Stack(
        fit: StackFit.expand,
        children: [
          chart,
          Padding(
            padding: EdgeInsets.all(
              widget.thickness + widget.highlightExpansion + 4,
            ),
            child: Center(child: centerBuilder(context, _active)),
          ),
        ],
      );
    }

    chart = Semantics(
      label: widget.semanticsLabel ?? _describe(),
      container: true,
      child: chart,
    );

    final size = widget.size;
    if (size != null) return SizedBox.square(dimension: size, child: chart);
    return AspectRatio(aspectRatio: 1, child: chart);
  }
}
