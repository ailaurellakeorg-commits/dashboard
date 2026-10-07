import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/dashboard_models.dart';

enum TrendAxisFormat { number, currency }

class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.points,
    required this.color,
    required this.axisFormat,
  });
  final List<TrendPoint> points;
  final Color color;
  final TrendAxisFormat axisFormat;

  @override
  Widget build(BuildContext context) {
    final labelCount = points.length < 7 ? points.length : 7;
    final labels = labelCount == 1
        ? [points.first]
        : List.generate(
            labelCount,
            (index) =>
                points[((points.length - 1) * index / (labelCount - 1))
                    .round()],
          );
    return SizedBox(
      height: 180,
      child: CustomPaint(
        painter: _TrendPainter(
          points: points,
          color: color,
          axisFormat: axisFormat,
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 152, left: 52),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels
                .map(
                  (point) => Text(
                    point.label,
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(color: AppTheme.muted),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({
    required this.points,
    required this.color,
    required this.axisFormat,
  });
  final List<TrendPoint> points;
  final Color color;
  final TrendAxisFormat axisFormat;

  @override
  void paint(Canvas canvas, Size size) {
    const chartHeight = 132.0;
    const plotLeft = 52.0;
    const plotRight = 4.0;
    final values = points
        .map((point) => point.value)
        .whereType<double>()
        .toList();
    if (values.isEmpty) return;
    final minimum = values.reduce((a, b) => a < b ? a : b);
    final maximum = values.reduce((a, b) => a > b ? a : b);
    final rawRange = (maximum - minimum)
        .abs()
        .clamp(1, double.infinity)
        .toDouble();
    final axisMinimum = minimum - rawRange * .08;
    final axisMaximum = maximum + rawRange * .08;
    final range = axisMaximum - axisMinimum;
    final plotWidth = size.width - plotLeft - plotRight;
    final grid = Paint()..color = AppTheme.line;
    for (var i = 0; i < 4; i++) {
      final y = chartHeight * i / 3;
      canvas.drawLine(Offset(plotLeft, y), Offset(size.width, y), grid);
      final tickValue = axisMaximum - range * i / 3;
      final label = TextPainter(
        text: TextSpan(
          text: _formatAxisValue(tickValue, axisFormat),
          style: const TextStyle(
            color: AppTheme.muted,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
      )..layout(maxWidth: plotLeft - 8);
      label.paint(
        canvas,
        Offset(
          plotLeft - label.width - 8,
          (y - label.height / 2).clamp(0, chartHeight - label.height),
        ),
      );
    }
    final step = points.length == 1 ? 0.0 : plotWidth / (points.length - 1);
    final line = Path();
    var segmentStarted = false;
    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1
          ? plotLeft + plotWidth / 2
          : plotLeft + i * step;
      final value = points[i].value;
      if (value == null) {
        segmentStarted = false;
        canvas.drawLine(
          Offset(x, 4),
          Offset(x, chartHeight - 4),
          Paint()
            ..color = AppTheme.red.withValues(alpha: .28)
            ..strokeWidth = 2,
        );
        canvas.drawCircle(
          Offset(x, chartHeight / 2),
          4,
          Paint()..color = AppTheme.red,
        );
        continue;
      }
      final y = chartHeight - (value - axisMinimum) / range * chartHeight;
      if (!segmentStarted) {
        line.moveTo(x, y);
        segmentStarted = true;
      } else {
        line.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 4.5, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = color);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_TrendPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.color != color ||
      oldDelegate.axisFormat != axisFormat;
}

String _formatAxisValue(double value, TrendAxisFormat format) {
  if (format == TrendAxisFormat.currency) {
    if (value.abs() >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value.abs() >= 1000) return '\$${(value / 1000).round()}K';
    return '\$${value.round()}';
  }
  return value.abs() >= 10
      ? value.round().toString()
      : value.toStringAsFixed(1);
}
