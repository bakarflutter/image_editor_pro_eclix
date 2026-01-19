import 'dart:ui' as ui;
import 'editor_state.dart';

/// Result returned from the image editor
class EditorResult {
  final ui.Image displayImage;
  final EditorState state;

  EditorResult({required this.displayImage, required this.state});
}
