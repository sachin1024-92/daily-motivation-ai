import 'dart:math';

import 'package:flutter/material.dart';

/// Engineering & exam toolkit: quick solvers students use every day.
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Engineering Toolkit'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Quadratic'),
              Tab(text: 'Ohm\'s law'),
              Tab(text: 'Resistors'),
              Tab(text: 'Units'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_QuadraticTool(), _OhmTool(), _ResistorTool(), _UnitTool()],
        ),
      ),
    );
  }
}

double? _num(String s) => double.tryParse(s.trim());

String fmt(double v) {
  if (v.isNaN || v.isInfinite) return '—';
  if (v == v.roundToDouble() && v.abs() < 1e9) return v.toStringAsFixed(0);
  return v.abs() >= 1e6 || v.abs() < 1e-3
      ? v.toStringAsExponential(3)
      : v.toStringAsFixed(4).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
}

/// Solves ax² + bx + c = 0. Returns a human-readable description.
String solveQuadratic(double a, double b, double c) {
  if (a == 0) {
    if (b == 0) return c == 0 ? 'Every x is a solution' : 'No solution';
    return 'Linear equation: x = ${fmt(-c / b)}';
  }
  final d = b * b - 4 * a * c;
  if (d > 0) {
    final r = sqrt(d);
    return 'D = ${fmt(d)} > 0 → two real roots\nx₁ = ${fmt((-b + r) / (2 * a))}\nx₂ = ${fmt((-b - r) / (2 * a))}';
  }
  if (d == 0) return 'D = 0 → equal roots\nx = ${fmt(-b / (2 * a))}';
  final re = -b / (2 * a);
  final im = sqrt(-d) / (2 * a).abs();
  return 'D = ${fmt(d)} < 0 → complex roots\nx = ${fmt(re)} ± ${fmt(im)}i';
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;

  const _Field(this.controller, this.label, this.onChanged);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        ),
      );
}

class _ResultCard extends StatelessWidget {
  final String text;

  const _ResultCard(this.text);

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(height: 1.5)),
        ),
      );
}

class _QuadraticTool extends StatefulWidget {
  const _QuadraticTool();

  @override
  State<_QuadraticTool> createState() => _QuadraticToolState();
}

class _QuadraticToolState extends State<_QuadraticTool> {
  final _a = TextEditingController(text: '1');
  final _b = TextEditingController(text: '-5');
  final _c = TextEditingController(text: '6');

  @override
  Widget build(BuildContext context) {
    final a = _num(_a.text), b = _num(_b.text), c = _num(_c.text);
    final out = (a == null || b == null || c == null)
        ? 'Enter numbers for a, b and c'
        : solveQuadratic(a, b, c);
    void refresh(String _) => setState(() {});
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('ax² + bx + c = 0'),
        const SizedBox(height: 12),
        _Field(_a, 'a', refresh),
        _Field(_b, 'b', refresh),
        _Field(_c, 'c', refresh),
        _ResultCard(out),
      ],
    );
  }
}

class _OhmTool extends StatefulWidget {
  const _OhmTool();

  @override
  State<_OhmTool> createState() => _OhmToolState();
}

class _OhmToolState extends State<_OhmTool> {
  final _v = TextEditingController();
  final _i = TextEditingController();
  final _r = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final v = _num(_v.text), i = _num(_i.text), r = _num(_r.text);
    String out = 'Fill any two values (V, I, R) to get the third and the power.';
    if (v != null && i != null && r == null && i != 0) {
      out = 'R = ${fmt(v / i)} Ω\nP = ${fmt(v * i)} W';
    } else if (v != null && r != null && i == null && r != 0) {
      out = 'I = ${fmt(v / r)} A\nP = ${fmt(v * v / r)} W';
    } else if (i != null && r != null && v == null) {
      out = 'V = ${fmt(i * r)} V\nP = ${fmt(i * i * r)} W';
    }
    void refresh(String _) => setState(() {});
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('V = I × R,   P = V × I'),
        const SizedBox(height: 12),
        _Field(_v, 'Voltage V (volts)', refresh),
        _Field(_i, 'Current I (amperes)', refresh),
        _Field(_r, 'Resistance R (ohms)', refresh),
        _ResultCard(out),
      ],
    );
  }
}

class _ResistorTool extends StatefulWidget {
  const _ResistorTool();

  @override
  State<_ResistorTool> createState() => _ResistorToolState();
}

class _ResistorToolState extends State<_ResistorTool> {
  final _values = TextEditingController(text: '6, 6, 6');

  @override
  Widget build(BuildContext context) {
    final rs = _values.text
        .split(RegExp(r'[,\s]+'))
        .map(_num)
        .whereType<double>()
        .where((r) => r > 0)
        .toList();
    final series = rs.fold<double>(0, (s, r) => s + r);
    final parallel = rs.isEmpty ? 0.0 : 1 / rs.fold<double>(0, (s, r) => s + 1 / r);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Enter resistances separated by commas (Ω)'),
        const SizedBox(height: 12),
        _Field(_values, 'e.g. 4, 6, 12', (_) => setState(() {})),
        _ResultCard(rs.isEmpty
            ? 'Enter at least one positive value'
            : 'Series: ${fmt(series)} Ω\nParallel: ${fmt(parallel)} Ω'),
      ],
    );
  }
}

class _Unit {
  final String name;
  final double toBase;

  const _Unit(this.name, this.toBase);
}

const Map<String, List<_Unit>> _unitGroups = {
  'Length': [
    _Unit('m', 1), _Unit('cm', 0.01), _Unit('mm', 0.001), _Unit('km', 1000),
    _Unit('inch', 0.0254), _Unit('ft', 0.3048), _Unit('Å', 1e-10),
  ],
  'Mass': [
    _Unit('kg', 1), _Unit('g', 0.001), _Unit('mg', 1e-6), _Unit('tonne', 1000), _Unit('lb', 0.45359237),
  ],
  'Energy': [
    _Unit('J', 1), _Unit('kJ', 1000), _Unit('cal', 4.184), _Unit('kWh', 3.6e6), _Unit('eV', 1.602176634e-19),
  ],
  'Pressure': [
    _Unit('Pa', 1), _Unit('kPa', 1000), _Unit('bar', 1e5), _Unit('atm', 101325), _Unit('mmHg', 133.322),
  ],
};

class _UnitTool extends StatefulWidget {
  const _UnitTool();

  @override
  State<_UnitTool> createState() => _UnitToolState();
}

class _UnitToolState extends State<_UnitTool> {
  String _group = 'Length';
  final _value = TextEditingController(text: '1');
  int _from = 0;

  @override
  Widget build(BuildContext context) {
    final units = _unitGroups[_group]!;
    final v = _num(_value.text);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SegmentedButton<String>(
          segments: [
            for (final g in _unitGroups.keys) ButtonSegment(value: g, label: Text(g)),
          ],
          selected: {_group},
          showSelectedIcon: false,
          onSelectionChanged: (s) => setState(() {
            _group = s.first;
            _from = 0;
          }),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _Field(_value, 'Value', (_) => setState(() {}))),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButton<int>(
                value: _from,
                items: [
                  for (var i = 0; i < units.length; i++)
                    DropdownMenuItem(value: i, child: Text(units[i].name)),
                ],
                onChanged: (i) => setState(() => _from = i ?? 0),
              ),
            ),
          ],
        ),
        if (v == null)
          const _ResultCard('Enter a number')
        else
          for (final u in units)
            ListTile(
              dense: true,
              title: Text(u.name),
              trailing: Text(fmt(v * units[_from].toBase / u.toBase),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
      ],
    );
  }
}
