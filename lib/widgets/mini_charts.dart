import 'dart:math';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
//  Mini Charts — Reusable chart widgets
// ═══════════════════════════════════════════════════════════════

// ── Spark Area Chart ──────────────────────────────────────────

class SparkAreaChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  final Color color;
  final double height;

  const SparkAreaChart({
    super.key,
    required this.data,
    required this.labels,
    required this.color,
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _SparkAreaPainter(data: data, color: color),
      ),
    );
  }
}

class _SparkAreaPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _SparkAreaPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxVal = data.reduce(max);
    final minVal = data.reduce(min);
    final range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height - ((data[i] - minVal) / range) * (size.height * 0.85);
      points.add(Offset(x, y));
    }

    // Area fill
    final areaPath = Path()..moveTo(0, size.height);
    for (final p in points) {
      areaPath.lineTo(p.dx, p.dy);
    }
    areaPath.lineTo(size.width, size.height);
    areaPath.close();

    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.02)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final linePath = Path();
    for (int i = 0; i < points.length; i++) {
      if (i == 0) {
        linePath.moveTo(points[i].dx, points[i].dy);
      } else {
        linePath.lineTo(points[i].dx, points[i].dy);
      }
    }
    canvas.drawPath(linePath, linePaint);

    // End dot
    if (points.isNotEmpty) {
      canvas.drawCircle(points.last, 4, Paint()..color = color);
      canvas.drawCircle(
          points.last, 6, Paint()..color = color.withValues(alpha: 0.25));
    }
  }

  @override
  bool shouldRepaint(covariant _SparkAreaPainter old) =>
      old.data != data || old.color != color;
}

// ── Donut Chart ───────────────────────────────────────────────

class DonutSegment {
  final String label;
  final double value;
  final Color color;

  DonutSegment(this.label, this.value, this.color);
}

class DonutChart extends StatelessWidget {
  final List<DonutSegment> segments;
  final double size;
  final String centerValue;
  final String centerLabel;

  const DonutChart({
    super.key,
    required this.segments,
    this.size = 120,
    this.centerValue = '',
    this.centerLabel = '',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(segments: segments),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (centerValue.isNotEmpty)
                Text(centerValue,
                    style: TextStyle(
                        fontSize: size * 0.16,
                        fontWeight: FontWeight.w700)),
              if (centerLabel.isNotEmpty)
                Text(centerLabel,
                    style: TextStyle(
                        fontSize: size * 0.09,
                        color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSegment> segments;

  _DonutPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<double>(0, (s, seg) => s + seg.value);
    if (total == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = radius * 0.28;
    double startAngle = -pi / 2;

    for (final seg in segments) {
      final sweep = (seg.value / total) * 2 * pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweep,
        false,
        Paint()
          ..color = seg.color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.butt,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.segments != segments;
}

// ── Progress Gauge ────────────────────────────────────────────

class ProgressGauge extends StatelessWidget {
  final double value;
  final Color color;
  final double size;
  final String label;

  const ProgressGauge({
    super.key,
    required this.value,
    required this.color,
    this.size = 100,
    this.label = '',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _GaugePainter(value: value, color: color),
            child: Center(
              child: Text(
                '${(value * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                    fontSize: size * 0.15,
                    fontWeight: FontWeight.w700,
                    color: color),
              ),
            ),
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700)),
        ],
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;

  _GaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const startAngle = -pi * 0.75;
    const totalSweep = pi * 1.5;

    // Background arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalSweep,
      false,
      Paint()
        ..color = Colors.grey.shade200
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Value arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalSweep * value.clamp(0, 1),
      false,
      Paint()
        ..color = color
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.value != value || old.color != color;
}
