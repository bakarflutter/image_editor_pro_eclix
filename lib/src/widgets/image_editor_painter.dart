import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Custom painter for rendering the image editor canvas
class ImageEditorPainter extends CustomPainter {
  final ui.Image image;
  final double scale;
  final Offset offset;
  final Rect? cropRect;
  final bool showCrop;
  final int rotationTurns;
  final bool flipHorizontal;
  final double brightness;
  final double contrast;
  final List<Offset?> erasePoints;
  final double eraseStrokeWidth;

  ImageEditorPainter({
    required this.image,
    required this.scale,
    required this.offset,
    this.cropRect,
    required this.showCrop,
    required this.rotationTurns,
    required this.flipHorizontal,
    required this.erasePoints,
    required this.eraseStrokeWidth,
    required this.brightness,
    required this.contrast,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawCheckeredBackground(canvas, size);

    canvas.saveLayer(null, Paint());

    double imageWidth = image.width.toDouble();
    double imageHeight = image.height.toDouble();

    if (rotationTurns % 2 != 0) {
      final temp = imageWidth;
      imageWidth = imageHeight;
      imageHeight = temp;
    }

    final centerX = offset.dx + imageWidth * scale / 2;
    final centerY = offset.dy + imageHeight * scale / 2;

    canvas.translate(centerX, centerY);

    if (rotationTurns != 0) {
      canvas.rotate(rotationTurns * math.pi / 2);
    }

    if (flipHorizontal) {
      canvas.scale(-1.0, 1.0);
    }

    canvas.scale(scale, scale);

    final double b = brightness * 255.0;
    final double c = contrast;
    final double contrastFactor = (1 + c);
    final double translate = 128 * (1 - contrastFactor);

    final Paint imgPaint = Paint()
      ..colorFilter = ColorFilter.matrix([
        contrastFactor,
        0,
        0,
        0,
        translate + b,
        0,
        contrastFactor,
        0,
        0,
        translate + b,
        0,
        0,
        contrastFactor,
        0,
        translate + b,
        0,
        0,
        0,
        1,
        0,
      ]);

    canvas.drawImage(
      image,
      Offset(-image.width / 2, -image.height / 2),
      imgPaint,
    );

    if (erasePoints.isNotEmpty) {
      final erasePaint = Paint()
        ..color = Colors.transparent
        ..strokeCap = StrokeCap.round
        ..strokeWidth = eraseStrokeWidth
        ..blendMode = BlendMode.clear;

      for (int i = 0; i < erasePoints.length - 1; i++) {
        if (erasePoints[i] != null && erasePoints[i + 1] != null) {
          canvas.drawLine(
            Offset(
              erasePoints[i]!.dx - image.width / 2,
              erasePoints[i]!.dy - image.height / 2,
            ),
            Offset(
              erasePoints[i + 1]!.dx - image.width / 2,
              erasePoints[i + 1]!.dy - image.height / 2,
            ),
            erasePaint,
          );
        }
      }
    }

    canvas.restore();

    if (showCrop && cropRect != null) {
      _drawCropOverlay(canvas, size);
    }
  }

  void _drawCheckeredBackground(Canvas canvas, Size size) {
    final paint1 = Paint()..color = Colors.white;
    final paint2 = Paint()..color = Colors.grey[300]!;
    const squareSize = 10.0;

    for (double y = 0; y < size.height; y += squareSize) {
      for (double x = 0; x < size.width; x += squareSize) {
        final isEven =
            ((x / squareSize).floor() + (y / squareSize).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, squareSize, squareSize),
          isEven ? paint1 : paint2,
        );
      }
    }
  }

  void _drawCropOverlay(Canvas canvas, Size size) {
    final darkPaint = Paint()..color = Colors.black.withOpacity(0.5);

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, cropRect!.top), darkPaint);
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        cropRect!.bottom,
        size.width,
        size.height - cropRect!.bottom,
      ),
      darkPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, cropRect!.top, cropRect!.left, cropRect!.height),
      darkPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        cropRect!.right,
        cropRect!.top,
        size.width - cropRect!.right,
        cropRect!.height,
      ),
      darkPaint,
    );

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(cropRect!, borderPaint);

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1;

    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(cropRect!.left + cropRect!.width * i / 3, cropRect!.top),
        Offset(cropRect!.left + cropRect!.width * i / 3, cropRect!.bottom),
        gridPaint,
      );
      canvas.drawLine(
        Offset(cropRect!.left, cropRect!.top + cropRect!.height * i / 3),
        Offset(cropRect!.right, cropRect!.top + cropRect!.height * i / 3),
        gridPaint,
      );
    }

    final handlePaint = Paint()..color = Colors.white;
    const handleLength = 20.0;
    const handleWidth = 4.0;

    _drawCornerHandle(
      canvas,
      cropRect!.topLeft,
      handlePaint,
      handleLength,
      handleWidth,
      true,
      true,
    );
    _drawCornerHandle(
      canvas,
      cropRect!.topRight,
      handlePaint,
      handleLength,
      handleWidth,
      false,
      true,
    );
    _drawCornerHandle(
      canvas,
      cropRect!.bottomLeft,
      handlePaint,
      handleLength,
      handleWidth,
      true,
      false,
    );
    _drawCornerHandle(
      canvas,
      cropRect!.bottomRight,
      handlePaint,
      handleLength,
      handleWidth,
      false,
      false,
    );
  }

  void _drawCornerHandle(
    Canvas canvas,
    Offset corner,
    Paint paint,
    double length,
    double width,
    bool left,
    bool top,
  ) {
    canvas.drawRect(
      Rect.fromLTWH(
        left ? corner.dx - width : corner.dx,
        top ? corner.dy - width : corner.dy - length,
        left ? length : width,
        length,
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        left ? corner.dx - width : corner.dx - length,
        top ? corner.dy - width : corner.dy,
        length,
        top ? length : width,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant ImageEditorPainter oldDelegate) => true;
}
