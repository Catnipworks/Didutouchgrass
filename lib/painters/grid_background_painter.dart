import 'package:flutter/material.dart';

class GridBackgroundPainter extends CustomPainter {
  final Color gridColor;
  final double spacing;
  final double strokeWidth;

  GridBackgroundPainter({
    this.gridColor = const Color(0xFFBCBCBC),
    this.spacing = 30.0,
    this.strokeWidth = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(GridBackgroundPainter oldDelegate) {
    return oldDelegate.gridColor != gridColor ||
        oldDelegate.spacing != spacing ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}