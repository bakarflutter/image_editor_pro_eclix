import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as math;
// import 'package:flutter_svg/svg.dart';

import '../models/editor_state.dart';
import '../models/editor_result.dart';
import '../utils/no_thumb_slider.dart';
import 'image_editor_painter.dart';

/// A comprehensive image editor widget with various editing capabilities
class ImageEditor extends StatefulWidget {
  /// The image file to edit
  final File imageFile;

  /// Previous editor state for restoring
  final EditorState? previousState;

  /// Custom colors configuration
  final ImageEditorColors? colors;

  /// Custom text labels
  final ImageEditorLabels? labels;

  /// Icon assets configuration
  final ImageEditorIcons? icons;

  const ImageEditor({
    super.key,
    required this.imageFile,
    this.previousState,
    this.colors,
    this.labels,
    this.icons,
  });

  @override
  State<ImageEditor> createState() => _ImageEditorState();
}

/// Configuration for editor colors
class ImageEditorColors {
  final Color backgroundColor;
  final Color primaryColor;
  final Color buttonColor;
  final Color buttonTextColor;

  const ImageEditorColors({
    this.backgroundColor = const Color(0xFFF5F5F5),
    this.primaryColor = const Color(0xFFFF6B35),
    this.buttonColor = const Color(0xFFFF6B35),
    this.buttonTextColor = Colors.white,
  });
}

/// Configuration for editor labels
class ImageEditorLabels {
  final String save;
  final String flipRotate;
  final String crop;
  final String erase;
  final String adjust;
  final String rotateLeft;
  final String rotateRight;
  final String flip;
  final String eraserSize;

  const ImageEditorLabels({
    this.save = 'Save',
    this.flipRotate = 'Flip/Rotate',
    this.crop = 'Crop',
    this.erase = 'Erase',
    this.adjust = 'Adjust',
    this.rotateLeft = 'Rotate Left',
    this.rotateRight = 'Rotate Right',
    this.flip = 'Flip',
    this.eraserSize = 'Eraser Size',
  });
}

/// Configuration for editor icons
class ImageEditorIcons {
  final String? undo;
  final String? redo;
  final String? brightness;
  final String? contrast;
  final String? flipRotate;
  final String? crop;
  final String? erase;
  final String? adjust;
  final String? rotateLeft;
  final String? rotateRight;
  final String? flipIcon;

  const ImageEditorIcons({
    this.undo,
    this.redo,
    this.brightness,
    this.contrast,
    this.flipRotate,
    this.crop,
    this.erase,
    this.adjust,
    this.rotateLeft,
    this.rotateRight,
    this.flipIcon,
  });
}

class _ImageEditorState extends State<ImageEditor> {
  final GlobalKey _canvasKey = GlobalKey();
  ui.Image? _originalImage;
  ui.Image? _displayImage;

  Rect? _cropRect;
  int _rotationTurns = 0;
  bool _flipHorizontal = false;
  bool _isCropping = false;
  bool _isErasing = false;
  bool _showFlipRotateMenu = false;
  bool _showAdjust = false;

  List<Offset?> _erasePoints = [];
  double _eraseStrokeWidth = 20.0;
  AdjustMode _selectedAdjust = AdjustMode.brightness;
  double _brightness = 0.0;
  double _contrast = 0.0;

  double _imageScale = 1.0;
  Offset _imageOffset = Offset.zero;

  final List<EditorSnapshot> _history = [];
  final List<EditorSnapshot> _redoStack = [];
  ResizeMode _resizeMode = ResizeMode.none;

  late ImageEditorColors _colors;
  late ImageEditorLabels _labels;
  late ImageEditorIcons _icons;

  @override
  void initState() {
    super.initState();
    _colors = widget.colors ?? const ImageEditorColors();
    _labels = widget.labels ?? const ImageEditorLabels();
    _icons = widget.icons ?? const ImageEditorIcons();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();

    setState(() {
      if (widget.previousState != null) {
        _originalImage = widget.previousState!.originalImage;
        _displayImage = widget.previousState!.originalImage;
        _cropRect = widget.previousState!.cropRect;
        _rotationTurns = widget.previousState!.rotationTurns;
        _flipHorizontal = widget.previousState!.flipHorizontal;
        _erasePoints = List.from(widget.previousState!.erasePoints);
        _brightness = widget.previousState!.brightness;
        _contrast = widget.previousState!.contrast;
      } else {
        _originalImage = frame.image;
        _displayImage = frame.image;
      }

      _calculateImageScale();
      _saveSnapshot();
    });
  }

  void _calculateImageScale() {
    if (_displayImage == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? box =
          _canvasKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) return;

      final containerSize = box.size;
      double imageWidth = _displayImage!.width.toDouble();
      double imageHeight = _displayImage!.height.toDouble();

      if (_rotationTurns % 2 != 0) {
        final temp = imageWidth;
        imageWidth = imageHeight;
        imageHeight = temp;
      }

      final scaleX = (containerSize.width - 40) / imageWidth;
      final scaleY = (containerSize.height - 40) / imageHeight;
      final scale = math.min(scaleX, scaleY);

      final scaledWidth = imageWidth * scale;
      final scaledHeight = imageHeight * scale;
      final offsetX = (containerSize.width - scaledWidth) / 2;
      final offsetY = (containerSize.height - scaledHeight) / 2;

      setState(() {
        _imageScale = scale;
        _imageOffset = Offset(offsetX, offsetY);

        if (_cropRect != null && _isCropping) {
          _cropRect = Rect.fromLTWH(
            _imageOffset.dx + scaledWidth * 0.1,
            _imageOffset.dy + scaledHeight * 0.1,
            scaledWidth * 0.8,
            scaledHeight * 0.8,
          );
        }
      });
    });
  }

  void _saveSnapshot() {
    _history.add(
      EditorSnapshot(
        displayImage: _displayImage!,
        cropRect: _cropRect,
        rotationTurns: _rotationTurns,
        flipHorizontal: _flipHorizontal,
        erasePoints: List.from(_erasePoints),
        brightness: _brightness,
        contrast: _contrast,
      ),
    );
    _redoStack.clear();
  }

  void _undo() {
    if (_history.length <= 1) return;
    _isCropping = false;

    final current = _history.removeLast();
    _redoStack.add(current);

    final previous = _history.last;
    setState(() {
      _displayImage = previous.displayImage;
      _cropRect = previous.cropRect;
      _rotationTurns = previous.rotationTurns;
      _flipHorizontal = previous.flipHorizontal;
      _erasePoints = List.from(previous.erasePoints);
      _brightness = previous.brightness;
      _contrast = previous.contrast;
    });
    _calculateImageScale();
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    _isCropping = false;

    final next = _redoStack.removeLast();
    _history.add(next);

    setState(() {
      _displayImage = next.displayImage;
      _cropRect = next.cropRect;
      _rotationTurns = next.rotationTurns;
      _flipHorizontal = next.flipHorizontal;
      _erasePoints = List.from(next.erasePoints);
      _brightness = next.brightness;
      _contrast = next.contrast;
    });
    _calculateImageScale();
  }

  Future<ui.Image?> _applyTransformations() async {
    if (_displayImage == null) return null;

    double width = _displayImage!.width.toDouble();
    double height = _displayImage!.height.toDouble();

    if (_rotationTurns % 2 != 0) {
      final temp = width;
      width = height;
      height = temp;
    }

    final pictureRecorder = ui.PictureRecorder();
    final transformCanvas = Canvas(pictureRecorder);

    transformCanvas.save();

    if (_rotationTurns != 0) {
      transformCanvas.translate(width / 2, height / 2);
      transformCanvas.rotate(_rotationTurns * math.pi / 2);
      transformCanvas.translate(
        -_displayImage!.width / 2,
        -_displayImage!.height / 2,
      );
    }

    if (_flipHorizontal) {
      transformCanvas.translate(_displayImage!.width.toDouble(), 0);
      transformCanvas.scale(-1.0, 1.0);
    }

    final double b = _brightness * 255.0;
    final double c = _contrast;
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

    transformCanvas.drawImage(_displayImage!, Offset.zero, imgPaint);

    if (_erasePoints.isNotEmpty) {
      final erasePaint = Paint()
        ..color = Colors.transparent
        ..strokeCap = StrokeCap.round
        ..strokeWidth = _eraseStrokeWidth
        ..blendMode = BlendMode.clear;

      for (int i = 0; i < _erasePoints.length - 1; i++) {
        if (_erasePoints[i] != null && _erasePoints[i + 1] != null) {
          transformCanvas.drawLine(
            _erasePoints[i]!,
            _erasePoints[i + 1]!,
            erasePaint,
          );
        }
      }
    }

    transformCanvas.restore();

    final picture = pictureRecorder.endRecording();
    return await picture.toImage(width.toInt(), height.toInt());
  }

  Future<ui.Image?> _applyCrop() async {
    if (_cropRect == null || _displayImage == null) return null;

    double displayWidth = _displayImage!.width.toDouble();
    double displayHeight = _displayImage!.height.toDouble();

    if (_rotationTurns % 2 != 0) {
      final temp = displayWidth;
      displayWidth = displayHeight;
      displayHeight = temp;
    }

    final imageRect = Rect.fromLTWH(
      (_cropRect!.left - _imageOffset.dx) / _imageScale,
      (_cropRect!.top - _imageOffset.dy) / _imageScale,
      _cropRect!.width / _imageScale,
      _cropRect!.height / _imageScale,
    );

    final transformedImage = await _applyTransformations();
    if (transformedImage == null) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawImageRect(
      transformedImage,
      imageRect,
      Rect.fromLTWH(0, 0, imageRect.width, imageRect.height),
      Paint(),
    );

    final picture = recorder.endRecording();
    return await picture.toImage(
      imageRect.width.toInt(),
      imageRect.height.toInt(),
    );
  }

  void _rotateLeft() {
    setState(() {
      _rotationTurns = (_rotationTurns - 1) % 4;
      if (_rotationTurns < 0) _rotationTurns = 3;
      _isCropping = false;
      _cropRect = null;
    });
    _calculateImageScale();
    _saveSnapshot();
  }

  void _rotateRight() {
    setState(() {
      _rotationTurns = (_rotationTurns + 1) % 4;
      _isCropping = false;
      _cropRect = null;
    });
    _calculateImageScale();
    _saveSnapshot();
  }

  void _flipImage() {
    setState(() {
      _flipHorizontal = !_flipHorizontal;
    });
    _saveSnapshot();
  }

  Future<void> onCropButtonPressed() async {
    if (_isCropping == true) {
      await _finishCrop();
    } else {
      _startCrop();
    }
  }

  void _startCrop() {
    setState(() {
      _isCropping = true;
      _showAdjust = false;
      _isErasing = false;
      _showFlipRotateMenu = false;

      double imageWidth = _displayImage!.width * _imageScale;
      double imageHeight = _displayImage!.height * _imageScale;

      if (_rotationTurns % 2 != 0) {
        final temp = imageWidth;
        imageWidth = imageHeight;
        imageHeight = temp;
      }

      _cropRect = Rect.fromLTWH(
        _imageOffset.dx + imageWidth * 0.1,
        _imageOffset.dy + imageHeight * 0.1,
        imageWidth * 0.8,
        imageHeight * 0.8,
      );
    });
  }

  Future<void> _finishCrop() async {
    final croppedImage = await _applyCrop();
    if (croppedImage != null) {
      setState(() {
        _displayImage = croppedImage;
        _cropRect = null;
        _isCropping = false;
        _rotationTurns = 0;
        _flipHorizontal = false;
        _erasePoints.clear();
        _brightness = 0.0;
        _contrast = 0.0;
      });
      _calculateImageScale();
      _saveSnapshot();
    }
  }

  void adjustBrightness(double value) {
    setState(() {
      _brightness = value.clamp(0.0, 1.0);
    });
  }

  void adjustContrast(double value) {
    setState(() {
      _contrast = value.clamp(-1.0, 1.0);
    });
  }

  void _applyAdjustments() {
    _saveSnapshot();
  }

  Future<void> _saveImage() async {
    ui.Image? finalImage;

    if (_isCropping && _cropRect != null) {
      finalImage = await _applyCrop();
    } else {
      finalImage = await _applyTransformations();
    }

    if (finalImage != null) {
      final state = EditorState(
        originalImage: finalImage,
        cropRect: null,
        rotationTurns: 0,
        flipHorizontal: false,
        erasePoints: [],
        brightness: 0.0,
        contrast: 0.0,
      );

      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        Navigator.pop(
          context,
          EditorResult(displayImage: finalImage, state: state),
        );
      }
    }
  }

  bool _isPointInImageBounds(Offset screenPoint) {
    double imageWidth = _displayImage!.width * _imageScale;
    double imageHeight = _displayImage!.height * _imageScale;

    if (_rotationTurns % 2 != 0) {
      final temp = imageWidth;
      imageWidth = imageHeight;
      imageHeight = temp;
    }

    final imageRect = Rect.fromLTWH(
      _imageOffset.dx,
      _imageOffset.dy,
      imageWidth,
      imageHeight,
    );

    return imageRect.contains(screenPoint);
  }

  void _onErasePanStart(DragStartDetails details) {
    final RenderBox? box =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final localPosition = box.globalToLocal(details.globalPosition);

    if (!_isPointInImageBounds(localPosition)) return;

    final imagePoint = _screenToImageCoordinates(localPosition);

    setState(() => _erasePoints.add(imagePoint));
  }

  void _onErasePanUpdate(DragUpdateDetails details) {
    final RenderBox? box =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final localPosition = box.globalToLocal(details.globalPosition);

    if (!_isPointInImageBounds(localPosition)) return;

    final imagePoint = _screenToImageCoordinates(localPosition);

    setState(() => _erasePoints.add(imagePoint));
  }

  void _onErasePanEnd(DragEndDetails details) {
    setState(() => _erasePoints.add(null));
    _saveSnapshot();
  }

  Offset _screenToImageCoordinates(Offset screenPoint) {
    double imageWidth = _displayImage!.width.toDouble();
    double imageHeight = _displayImage!.height.toDouble();

    double centerX = _imageOffset.dx;
    double centerY = _imageOffset.dy;

    if (_rotationTurns % 2 != 0) {
      centerX += imageHeight * _imageScale / 2;
      centerY += imageWidth * _imageScale / 2;
    } else {
      centerX += imageWidth * _imageScale / 2;
      centerY += imageHeight * _imageScale / 2;
    }

    double x = screenPoint.dx - centerX;
    double y = screenPoint.dy - centerY;

    switch (_rotationTurns % 4) {
      case 1:
        final temp = x;
        x = y;
        y = -temp;
        break;
      case 2:
        x = -x;
        y = -y;
        break;
      case 3:
        final temp = x;
        x = -y;
        y = temp;
        break;
    }

    if (_flipHorizontal) {
      x = -x;
    }

    x = x / _imageScale + imageWidth / 2;
    y = y / _imageScale + imageHeight / 2;

    return Offset(x, y);
  }

  void _onCropPanStart(DragStartDetails details) {
    if (_cropRect == null) return;

    final position = details.localPosition;
    const handleSize = 40.0;

    if ((position.dx - _cropRect!.left).abs() < handleSize &&
        (position.dy - _cropRect!.top).abs() < handleSize) {
      _resizeMode = ResizeMode.topLeft;
    } else if ((position.dx - _cropRect!.right).abs() < handleSize &&
        (position.dy - _cropRect!.top).abs() < handleSize) {
      _resizeMode = ResizeMode.topRight;
    } else if ((position.dx - _cropRect!.left).abs() < handleSize &&
        (position.dy - _cropRect!.bottom).abs() < handleSize) {
      _resizeMode = ResizeMode.bottomLeft;
    } else if ((position.dx - _cropRect!.right).abs() < handleSize &&
        (position.dy - _cropRect!.bottom).abs() < handleSize) {
      _resizeMode = ResizeMode.bottomRight;
    } else if (_cropRect!.contains(position)) {
      _resizeMode = ResizeMode.move;
    }
  }

  void _onCropPanUpdate(DragUpdateDetails details) {
    if (_cropRect == null) return;

    final delta = details.delta;

    double displayWidth = _displayImage!.width * _imageScale;
    double displayHeight = _displayImage!.height * _imageScale;

    if (_rotationTurns % 2 != 0) {
      final temp = displayWidth;
      displayWidth = displayHeight;
      displayHeight = temp;
    }

    final imageRect = Rect.fromLTWH(
      _imageOffset.dx,
      _imageOffset.dy,
      displayWidth,
      displayHeight,
    );

    setState(() {
      switch (_resizeMode) {
        case ResizeMode.topLeft:
          _cropRect = Rect.fromLTRB(
            (_cropRect!.left + delta.dx).clamp(
              imageRect.left,
              _cropRect!.right - 50,
            ),
            (_cropRect!.top + delta.dy).clamp(
              imageRect.top,
              _cropRect!.bottom - 50,
            ),
            _cropRect!.right,
            _cropRect!.bottom,
          );
          break;
        case ResizeMode.topRight:
          _cropRect = Rect.fromLTRB(
            _cropRect!.left,
            (_cropRect!.top + delta.dy).clamp(
              imageRect.top,
              _cropRect!.bottom - 50,
            ),
            (_cropRect!.right + delta.dx).clamp(
              _cropRect!.left + 50,
              imageRect.right,
            ),
            _cropRect!.bottom,
          );
          break;
        case ResizeMode.bottomLeft:
          _cropRect = Rect.fromLTRB(
            (_cropRect!.left + delta.dx).clamp(
              imageRect.left,
              _cropRect!.right - 50,
            ),
            _cropRect!.top,
            _cropRect!.right,
            (_cropRect!.bottom + delta.dy).clamp(
              _cropRect!.top + 50,
              imageRect.bottom,
            ),
          );
          break;
        case ResizeMode.bottomRight:
          _cropRect = Rect.fromLTRB(
            _cropRect!.left,
            _cropRect!.top,
            (_cropRect!.right + delta.dx).clamp(
              _cropRect!.left + 50,
              imageRect.right,
            ),
            (_cropRect!.bottom + delta.dy).clamp(
              _cropRect!.top + 50,
              imageRect.bottom,
            ),
          );
          break;
        case ResizeMode.move:
          final newRect = _cropRect!.shift(delta);
          if (imageRect.contains(newRect.topLeft) &&
              imageRect.contains(newRect.bottomRight)) {
            _cropRect = newRect;
          }
          break;
        case ResizeMode.none:
          break;
      }
    });
  }

  Future<void> _applyCropIfNeeded() async {
    if (_isCropping && _cropRect != null) {
      await _finishCrop();
    }
  }

  Widget _buildIconButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback? onTap,
    double size = 24,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Icon(
        icon,
        size: size,
        color: enabled ? Colors.black : Colors.grey.shade400,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _colors.backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 5),
              // Top toolbar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                color: _colors.backgroundColor,
                child: Row(
                  children: [
                    _buildIconButton(
                      icon: Icons.undo,
                      enabled: _history.length > 1,
                      onTap: _history.length > 1 ? _undo : null,
                    ),
                    const SizedBox(width: 18),
                    _buildIconButton(
                      icon: Icons.redo,
                      enabled: _redoStack.isNotEmpty,
                      onTap: _redoStack.isNotEmpty ? _redo : null,
                    ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _colors.buttonColor,
                        foregroundColor: _colors.buttonTextColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _saveImage,
                      child: Text(_labels.save),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Canvas
              Expanded(
                child: _displayImage == null
                    ? const Center(child: CircularProgressIndicator())
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return GestureDetector(
                            onPanStart: _isCropping
                                ? _onCropPanStart
                                : (_isErasing ? _onErasePanStart : null),
                            onPanUpdate: _isCropping
                                ? _onCropPanUpdate
                                : (_isErasing ? _onErasePanUpdate : null),
                            onPanEnd: _isErasing ? _onErasePanEnd : null,
                            child: SizedBox(
                              key: _canvasKey,
                              width: constraints.maxWidth,
                              height: constraints.maxHeight,
                              child: CustomPaint(
                                painter: ImageEditorPainter(
                                  image: _displayImage!,
                                  scale: _imageScale,
                                  offset: _imageOffset,
                                  cropRect: _cropRect,
                                  showCrop: _isCropping,
                                  rotationTurns: _rotationTurns,
                                  flipHorizontal: _flipHorizontal,
                                  brightness: _brightness,
                                  contrast: _contrast,
                                  erasePoints: _erasePoints,
                                  eraseStrokeWidth: _eraseStrokeWidth,
                                ),
                                size: Size(
                                  constraints.maxWidth,
                                  constraints.maxHeight,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 20),

              // Adjustment controls
              if (_showAdjust)
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          _buildAdjustButton(
                            Icons.brightness_6,
                            () => setState(
                              () => _selectedAdjust = AdjustMode.brightness,
                            ),
                            _selectedAdjust == AdjustMode.brightness,
                          ),
                          const SizedBox(width: 20),
                          _buildAdjustButton(
                            Icons.contrast,
                            () => setState(
                              () => _selectedAdjust = AdjustMode.contrast,
                            ),
                            _selectedAdjust == AdjustMode.contrast,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_selectedAdjust == AdjustMode.brightness)
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 15,
                            thumbColor: Colors.white,
                            thumbShape: const BottomThumbShape(
                              thumbRadius: 7,
                              verticalOffset: 10,
                            ),
                            overlayShape: SliderComponentShape.noOverlay,
                            activeTrackColor: Colors.grey.shade600,
                            inactiveTrackColor: Colors.grey.shade200,
                          ),
                          child: Slider(
                            value: _brightness,
                            min: 0.0,
                            max: 1.0,
                            onChanged: adjustBrightness,
                            onChangeEnd: (_) => _applyAdjustments(),
                          ),
                        ),
                      if (_selectedAdjust == AdjustMode.contrast)
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 15,
                            thumbColor: Colors.white,
                            thumbShape: const BottomThumbShape(
                              thumbRadius: 7,
                              verticalOffset: 10,
                            ),
                            overlayShape: SliderComponentShape.noOverlay,
                            activeTrackColor: Colors.grey.shade600,
                            inactiveTrackColor: Colors.grey.shade200,
                          ),
                          child: Slider(
                            min: -1.0,
                            max: 1.0,
                            value: _contrast,
                            onChanged: adjustContrast,
                            onChangeEnd: (_) => _applyAdjustments(),
                          ),
                        ),
                    ],
                  ),
                ),

              // Eraser controls
              if (_isErasing)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Text(
                        '${_labels.eraserSize}:',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 15,
                            thumbColor: Colors.white,
                            thumbShape: const BottomThumbShape(
                              thumbRadius: 7,
                              verticalOffset: 10,
                            ),
                            overlayShape: SliderComponentShape.noOverlay,
                            activeTrackColor: Colors.grey.shade600,
                            inactiveTrackColor: Colors.grey.shade200,
                          ),
                          child: Slider(
                            min: 1,
                            max: 50,
                            value: _eraseStrokeWidth,
                            onChanged: (value) =>
                                setState(() => _eraseStrokeWidth = value),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Flip/Rotate menu
              if (_showFlipRotateMenu)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMenuButton(
                        Icons.rotate_left,
                        _labels.rotateLeft,
                        _rotateLeft,
                      ),
                      const SizedBox(width: 40),
                      _buildMenuButton(
                        Icons.rotate_right,
                        _labels.rotateRight,
                        _rotateRight,
                      ),
                      const SizedBox(width: 40),
                      _buildMenuButton(Icons.flip, _labels.flip, _flipImage),
                    ],
                  ),
                ),

              Container(
                height: 1,
                color: Colors.grey.shade300,
                width: double.infinity,
              ),

              // Bottom toolbar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: const BoxDecoration(color: Colors.white),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildToolButton(
                      icon: Icons.flip_camera_android,
                      label: _labels.flipRotate,
                      onTap: () async {
                        await _applyCropIfNeeded();
                        setState(() {
                          _showFlipRotateMenu = !_showFlipRotateMenu;
                          _isErasing = false;
                          _showAdjust = false;
                        });
                      },
                      isActive: _showFlipRotateMenu,
                    ),
                    _buildToolButton(
                      icon: Icons.crop,
                      label: _labels.crop,
                      onTap: onCropButtonPressed,
                      isActive: _isCropping,
                    ),
                    _buildToolButton(
                      icon: Icons.auto_fix_high,
                      label: _labels.erase,
                      onTap: () async {
                        await _applyCropIfNeeded();
                        setState(() {
                          _isErasing = !_isErasing;
                          _showFlipRotateMenu = false;
                          _showAdjust = false;
                        });
                      },
                      isActive: _isErasing,
                    ),
                    _buildToolButton(
                      icon: Icons.tune,
                      label: _labels.adjust,
                      onTap: () async {
                        await _applyCropIfNeeded();
                        setState(() {
                          _showAdjust = !_showAdjust;
                          _isErasing = false;
                          _showFlipRotateMenu = false;
                        });
                      },
                      isActive: _showAdjust,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 24)],
      ),
    );
  }

  Widget _buildAdjustButton(IconData icon, VoidCallback onTap, bool isActive) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? _colors.backgroundColor : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 24),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? _colors.backgroundColor : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                child: Icon(icon, size: 24),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
