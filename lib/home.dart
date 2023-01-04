import 'dart:io';
import 'package:google_geocoding_api/google_geocoding_api.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool textScanning = false;
  XFile? imageFile;
  String scannedText = '';

  @override
  void initState() {
    super.initState();
  }

  void getImage([ImageSource source = ImageSource.gallery]) async {
    try {
      final pickedImage = await ImagePicker()
          .pickImage(source: source);

      if (pickedImage != null) {
        textScanning = true;
        imageFile = pickedImage;
        setState(() {});
        await getRecognizedText(pickedImage);
        textScanning = false;
        setState(() {});
      }
    } catch (e) {
      textScanning = false;
      imageFile = null;
      setState(() {});
      scannedText = 'Error:\n$e';
    }
  }

  Future getRecognizedText(XFile image) async {
    // 입력 이미지
    final inputImage = InputImage.fromFilePath(image.path);

    // 인식자 생성 - 한국어 지원
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);

    // 문자열 인식 함수 호출 (Text Recognition)
    RecognizedText recognisedText = await textRecognizer.processImage(inputImage);

    scannedText = '';

    // 인식된 문자열 추출
    for (TextBlock block in recognisedText.blocks) {
      for (TextLine line in block.lines) {
        for (TextElement element in line.elements) {
          scannedText += '${element.text} ';
        }
      }
    }

    textScanning = false;

    setState(() {});
    await textRecognizer.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('text recognition'),
        actions: [
          IconButton(
            onPressed: () {Navigator.pushNamed(context, '/publicApi'); },
            icon: const Icon(Icons.map_outlined),
          ),
          IconButton(
            onPressed: () {Navigator.pushNamed(context, '/geolocation'); },
            icon: const Icon(Icons.map),
          ),
          IconButton(
            onPressed:() => getImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
          ),
          IconButton(
            onPressed: getImage,
            icon: const Icon(Icons.photo),
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!textScanning && imageFile == null)
                Container(
                  width: 350.0,
                  height: 350.0,
                  color: Colors.grey.withOpacity(.5),
                ),
                if (imageFile != null)
                Container(
                  width: 350.0,
                  height: 350.0,
                  color: Colors.grey.withOpacity(.5),
                  child: Image.file(
                    File(imageFile!.path),
                    fit: BoxFit.fill,
                  ),
                ),
                const SizedBox(height: 20.0),
                Container(
                  padding: const EdgeInsets.all(10.0),
                  color: Theme.of(context).primaryColor.withOpacity(.3),
                  width: 350.0,
                  height: 350.0,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Text(scannedText,
                      style: const TextStyle(fontSize: 25.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (textScanning)
          const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}