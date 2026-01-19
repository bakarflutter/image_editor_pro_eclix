import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Represents the state of the image editor
class EditorState {
  final ui.Image originalImage;
  final Rect? cropRect;
  final int rotationTurns;
  final bool flipHorizontal;
  final List<Offset?> erasePoints;
  final double brightness;
  final double contrast;

  EditorState({
    required this.originalImage,
    this.cropRect,
    required this.rotationTurns,
    required this.flipHorizontal,
    required this.erasePoints,
    required this.brightness,
    required this.contrast,
  });
}

/// Snapshot for undo/redo functionality
class EditorSnapshot {
  final ui.Image displayImage;
  final Rect? cropRect;
  final int rotationTurns;
  final bool flipHorizontal;
  final List<Offset?> erasePoints;
  final double brightness;
  final double contrast;

  EditorSnapshot({
    required this.displayImage,
    this.cropRect,
    required this.rotationTurns,
    required this.flipHorizontal,
    required this.erasePoints,
    required this.brightness,
    required this.contrast,
  });
}

/// Modes for image adjustment
enum AdjustMode { brightness, contrast }

/// Modes for crop resizing
enum ResizeMode { none, topLeft, topRight, bottomLeft, bottomRight, move }
