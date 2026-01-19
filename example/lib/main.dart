import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_editor_pro_eclix/image_editor_pro_eclix.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Editor Pro Eclix Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _imageFile;
  ui.Image? _editedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
      _openEditor();
    }
  }

  Future<void> _openEditor() async {
    if (_imageFile == null) return;

    final result = await Navigator.push<EditorResult>(
      context,
      MaterialPageRoute(
        builder: (context) => ImageEditor(
          imageFile: _imageFile!,
          colors: const ImageEditorColors(
            backgroundColor: Color(0xFFF5F5F5),
            primaryColor: Color(0xFFFF6B35),
            buttonColor: Color(0xFFFF6B35),
            buttonTextColor: Colors.white,
          ),
          labels: const ImageEditorLabels(
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
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _editedImage = result.displayImage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Image Editor Pro Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_editedImage != null)
              Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: RawImage(
                    image: _editedImage,
                    width: 300,
                    height: 300,
                    fit: BoxFit.contain,
                  ),
                ),
              )
            else
              Container(
                margin: const EdgeInsets.all(20),
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: const Center(child: Text('No image selected')),
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Pick Image'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
