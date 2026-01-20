Image Editor Pro EclixTech is a modern **Flutter image editor library** for Android, iOS, Web, Windows, macOS, and Linux.
It provides advanced image editing features such as crop, rotate, flip, erase, brightness adjustment, and undo/redo support.

This package is ideal for Flutter developers building photo editing, document signing, or image annotation applications.


## Features

✨ **Comprehensive Editing Tools**
- 🖼️ **Crop**: Interactive crop with resizable handles
- 🔄 **Rotate**: 90° rotations (left/right)
- 🔃 **Flip**: Horizontal flip
- ✏️ **Erase**: Custom eraser with adjustable brush size
- ☀️ **Brightness**: Adjustable brightness control
- 🎨 **Contrast**: Adjustable contrast control
- ↩️ **Undo/Redo**: Full history support

🎯 **Easy to Use**
- Simple API with minimal setup
- Customizable colors and labels
- Material Design UI
- Responsive canvas

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  image_editor_pro_eclix: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## Usage

### Basic Usage

```dart
import 'package:image_editor_pro_eclix/image_editor_pro_eclix.dart';
import 'dart:io';

// Open the editor
final result = await Navigator.push<EditorResult>(
  context,
  MaterialPageRoute(
    builder: (context) => ImageEditor(
      imageFile: File('path/to/image.jpg'),
    ),
  ),
);

// Access the edited image
if (result != null) {
  final editedImage = result.displayImage; // ui.Image
  final state = result.state; // EditorState
}
```

### Custom Colors

```dart
ImageEditor(
  imageFile: imageFile,
  colors: ImageEditorColors(
    backgroundColor: Color(0xFFF5F5F5),
    primaryColor: Color(0xFFFF6B35),
    buttonColor: Color(0xFFFF6B35),
    buttonTextColor: Colors.white,
  ),
)
```

### Custom Labels (Localization)

```dart
ImageEditor(
  imageFile: imageFile,
  labels: ImageEditorLabels(
    save: 'Save',
    flipRotate: 'Flip/Rotate',
    crop: 'Crop',
    erase: 'Erase',
    adjust: 'Adjust',
    rotateLeft: 'Rotate Left',
    rotateRight: 'Rotate Right',
    flip: 'Flip',
    eraserSize: 'Eraser Size',
  ),
)
```

### Restore Previous State

```dart
EditorState? previousState;

// First edit
final result = await Navigator.push<EditorResult>(
  context,
  MaterialPageRoute(
    builder: (context) => ImageEditor(
      imageFile: imageFile,
    ),
  ),
);

if (result != null) {
  previousState = result.state;
}

// Resume editing with previous state
final result2 = await Navigator.push<EditorResult>(
  context,
  MaterialPageRoute(
    builder: (context) => ImageEditor(
      imageFile: imageFile,
      previousState: previousState,
    ),
  ),
);
```

## API Reference

### ImageEditor

Main widget for the image editor.

**Parameters:**
- `imageFile` (File, required): The image file to edit
- `previousState` (EditorState?, optional): Previous editor state for restoration
- `colors` (ImageEditorColors?, optional): Custom color configuration
- `labels` (ImageEditorLabels?, optional): Custom text labels
- `icons` (ImageEditorIcons?, optional): Custom icon assets

### EditorResult

Result returned from the editor.

**Properties:**
- `displayImage` (ui.Image): The edited image
- `state` (EditorState): The current editor state

### EditorState

State of the editor for restoration.

**Properties:**
- `originalImage` (ui.Image): The original image
- `cropRect` (Rect?): Crop rectangle if any
- `rotationTurns` (int): Number of 90° rotations
- `flipHorizontal` (bool): Whether image is flipped
- `erasePoints` (List<Offset?>): Erase stroke points
- `brightness` (double): Brightness value (0.0 to 1.0)
- `contrast` (double): Contrast value (-1.0 to 1.0)

### ImageEditorColors

Color configuration for the editor.

**Properties:**
- `backgroundColor` (Color): Background color
- `primaryColor` (Color): Primary accent color
- `buttonColor` (Color): Save button color
- `buttonTextColor` (Color): Button text color

### ImageEditorLabels

Text labels for localization.

**Properties:**
- `save` (String): Save button text
- `flipRotate` (String): Flip/Rotate tool label
- `crop` (String): Crop tool label
- `erase` (String): Erase tool label
- `adjust` (String): Adjust tool label
- `rotateLeft` (String): Rotate left label
- `rotateRight` (String): Rotate right label
- `flip` (String): Flip label
- `eraserSize` (String): Eraser size label

## Example

Check out the [example](example/) directory for a complete working example.

To run the example:

```bash
cd example
flutter pub get
flutter run
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

## Support

If you encounter any issues or have questions, please file an issue on the [GitHub repository](https://github.com/yourusername/image_editor_pro_eclix/issues).