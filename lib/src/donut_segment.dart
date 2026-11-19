import 'package:flutter/widgets.dart';

/// A single slice of a [DonutChart].
@immutable
class DonutSegment {
  /// Creates a segment with a [value], a [color] and an optional [label].
  ///
  /// Zero, negative and non-finite values are allowed but are not drawn.
  const DonutSegment({
    required this.value,
    required this.color,
    this.label,
  });

  /// The value of this segment. Its share of the total sets its size.
  final double value;

  /// The fill color of this segment.
  final Color color;

  /// A human-readable label, used by [DonutLegend] and for accessibility.
  final String? label;

  /// Returns a copy of this segment with the given fields replaced.
  DonutSegment copyWith({double? value, Color? color, String? label}) {
    return DonutSegment(
      value: value ?? this.value,
      color: color ?? this.color,
      label: label ?? this.label,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DonutSegment &&
          other.value == value &&
          other.color == color &&
          other.label == label;

  @override
  int get hashCode => Object.hash(value, color, label);

  @override
  String toString() => 'DonutSegment($label: $value)';
}
