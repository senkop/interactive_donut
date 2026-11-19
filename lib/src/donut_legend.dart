import 'package:flutter/material.dart';

import 'donut_geometry.dart';
import 'donut_segment.dart';

/// A legend for a [DonutChart], showing a color dot, label and share for
/// each segment.
///
/// Pair it with [DonutChart.onSelectionChanged] and [selectedIndex] to keep
/// the chart and the legend in sync.
class DonutLegend extends StatelessWidget {
  /// Creates a legend for [segments].
  const DonutLegend({
    super.key,
    required this.segments,
    this.selectedIndex,
    this.onTap,
    this.direction = Axis.vertical,
    this.showPercentages = true,
    this.valueFormatter,
    this.textStyle,
    this.dotSize = 10,
    this.spacing = 8,
  });

  /// The segments to describe. Usually the same list given to the chart.
  final List<DonutSegment> segments;

  /// The highlighted entry. Other entries are dimmed when this is set.
  final int? selectedIndex;

  /// Called with the index of an entry when it is tapped.
  final ValueChanged<int>? onTap;

  /// [Axis.vertical] lists entries in a column, [Axis.horizontal] wraps
  /// them in rows.
  final Axis direction;

  /// Whether each entry shows its share in percent.
  final bool showPercentages;

  /// Optional formatter for the raw value, shown after the label.
  final String Function(double value)? valueFormatter;

  /// Text style of the entries. Defaults to the ambient body style.
  final TextStyle? textStyle;

  /// Diameter of the color dot.
  final double dotSize;

  /// Space between entries.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final percents = percentagesOf([for (final s in segments) s.value]);
    final baseStyle = textStyle ?? DefaultTextStyle.of(context).style;

    final items = <Widget>[
      for (var i = 0; i < segments.length; i++)
        _LegendItem(
          segment: segments[i],
          label: segments[i].label ?? 'Segment ${i + 1}',
          percent: showPercentages ? percents[i] : null,
          formattedValue: valueFormatter?.call(segments[i].value),
          selected: i == selectedIndex,
          dimmed: selectedIndex != null && i != selectedIndex,
          style: baseStyle,
          dotSize: dotSize,
          onTap: onTap == null ? null : () => onTap!(i),
        ),
    ];

    if (direction == Axis.horizontal) {
      return Wrap(
        spacing: spacing * 2,
        runSpacing: spacing,
        children: items,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: EdgeInsets.symmetric(vertical: spacing / 2),
            child: item,
          ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.segment,
    required this.label,
    required this.percent,
    required this.formattedValue,
    required this.selected,
    required this.dimmed,
    required this.style,
    required this.dotSize,
    required this.onTap,
  });

  final DonutSegment segment;
  final String label;
  final double? percent;
  final String? formattedValue;
  final bool selected;
  final bool dimmed;
  final TextStyle style;
  final double dotSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textStyle =
        selected ? style.copyWith(fontWeight: FontWeight.bold) : style;
    Widget row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: segment.color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: dotSize * 0.8),
        Text(label, style: textStyle),
        if (formattedValue != null) ...[
          const SizedBox(width: 6),
          Text(formattedValue!, style: textStyle),
        ],
        if (percent != null) ...[
          const SizedBox(width: 6),
          Text('${percent!.toStringAsFixed(1)}%', style: textStyle),
        ],
      ],
    );

    row = AnimatedOpacity(
      opacity: dimmed ? 0.45 : 1,
      duration: const Duration(milliseconds: 150),
      child: row,
    );

    if (onTap == null) return row;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: row,
      ),
    );
  }
}
