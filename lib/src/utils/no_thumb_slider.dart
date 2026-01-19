// import 'package:flutter/material.dart';

// /// Custom thumb shape for sliders with vertical offset
// class BottomThumbShape extends SliderComponentShape {
//   final double thumbRadius;
//   final double verticalOffset;

//   const BottomThumbShape({this.thumbRadius = 6.0, this.verticalOffset = 0.0});

//   @override
//   Size getPreferredSize(bool isEnabled, bool isDiscrete) {
//     return Size.fromRadius(thumbRadius);
//   }

//   @override
//   void paint(
//     PaintingContext context,
//     Offset center, {
//     required Animation<double> activationAnimation,
//     required Animation<double> enableAnimation,
//     required bool isDiscrete,
//     required TextPainter labelPainter,
//     required RenderBox parentBox,
//     required SliderThemeData sliderTheme,
//     required TextDirection textDirection,
//     required double value,
//     required double textScaleFactor,
//     required Size sizeWithOverflow,
//   }) {
//     final Canvas canvas = context.canvas;

//     final adjustedCenter = Offset(center.dx, center.dy + verticalOffset);

//     final paint = Paint()
//       ..color = sliderTheme.thumbColor ?? Colors.white
//       ..style = PaintingStyle.fill;

//     canvas.drawCircle(adjustedCenter, thumbRadius, paint);

//     final borderPaint = Paint()
//       ..color = Colors.grey.shade400
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.5;

//     canvas.drawCircle(adjustedCenter, thumbRadius, borderPaint);
//   }
// }
