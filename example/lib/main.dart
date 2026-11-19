import 'dart:math';

import 'package:flutter/material.dart';
import 'package:interactive_donut/interactive_donut.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'interactive_donut',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  static const _names = ['Rent', 'Food', 'Transport', 'Fun', 'Savings'];
  static const _colors = [
    Color(0xFF5B5BD6),
    Color(0xFF12A594),
    Color(0xFFF5A524),
    Color(0xFFE5484D),
    Color(0xFF3E63DD),
  ];

  final _random = Random();
  late List<DonutSegment> _segments = _generate();
  int? _selected;
  bool _rounded = false;
  double _thickness = 28;

  List<DonutSegment> _generate() => [
        for (var i = 0; i < _names.length; i++)
          DonutSegment(
            value: (50 + _random.nextInt(450)).toDouble(),
            color: _colors[i],
            label: _names[i],
          ),
      ];

  double get _total => _segments.fold(0, (sum, s) => sum + s.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('interactive_donut')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() {
          _segments = _generate();
          _selected = null;
        }),
        icon: const Icon(Icons.shuffle),
        label: const Text('Shuffle data'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Wrap(
            spacing: 48,
            runSpacing: 32,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DonutChart(
                size: 280,
                segments: _segments,
                thickness: _thickness,
                roundedEnds: _rounded,
                gapDegrees: _rounded ? 6 : 2,
                trackColor: theme.colorScheme.surfaceContainerHighest,
                selectedIndex: _selected,
                onSelectionChanged: (i) => setState(() => _selected = i),
                centerBuilder: (context, i) {
                  final value = i == null ? _total : _segments[i].value;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        i == null ? 'Total' : _segments[i].label!,
                        style: theme.textTheme.labelLarge,
                      ),
                      Text(
                        '\$${value.toStringAsFixed(0)}',
                        style: theme.textTheme.headlineMedium,
                      ),
                    ],
                  );
                },
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DonutLegend(
                    segments: _segments,
                    selectedIndex: _selected,
                    valueFormatter: (v) => '\$${v.toStringAsFixed(0)}',
                    onTap: (i) => setState(
                      () => _selected = _selected == i ? null : i,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 240,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Rounded ends'),
                      value: _rounded,
                      onChanged: (v) => setState(() => _rounded = v),
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: Slider(
                      min: 8,
                      max: 60,
                      value: _thickness,
                      label: 'Thickness',
                      onChanged: (v) => setState(() => _thickness = v),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
