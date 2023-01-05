import 'dart:io';
import 'package:google_geocoding_api/google_geocoding_api.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_maps_utils/google_maps_utils.dart' as util;
import 'dart:math';

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
      final pickedImage = await ImagePicker().pickImage(source: source);

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
    RecognizedText recognisedText =
        await textRecognizer.processImage(inputImage);

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
            onPressed: () {
              Navigator.pushNamed(context, '/publicApi');
            },
            icon: const Icon(Icons.map_outlined),
          ),
          IconButton(
            onPressed: () {
              GeoCode();
            },
            icon: const Icon(Icons.map),
          ),
          IconButton(
            onPressed: () => getImage(ImageSource.camera),
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
                    height: 150.0,
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
                  height: 150.0,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Text(
                      scannedText,
                      style: const TextStyle(fontSize: 25.0),
                    ),
                  ),
                ),
                // const SizedBox(height: 20.0),
                // Container(
                //   padding: const EdgeInsets.all(10.0),
                //   color: Theme.of(context).primaryColor.withOpacity(.3),
                //   width: 350.0,
                //   height: 150.0,
                //   child: SingleChildScrollView(
                //     scrollDirection: Axis.vertical,
                //     physics: const AlwaysScrollableScrollPhysics(),
                //     child: Text(
                //       textScanning ? GeoCode().toString() : 'No text Scanned',
                //       style: const TextStyle(fontSize: 25.0),
                //     ),
                //   ),
                // )
              ],
            ),
          ),
          if (textScanning) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Future<void> GeoCode() async {
    const String googelApiKey = 'AIzaSyBrAdaZUxs-rN6KR2ExrqpKQHnZBRH0uQ4';
    final bool isDebugMode = true;
    final api = GoogleGeocodingApi(googelApiKey, isLogged: isDebugMode);
    final searchResults1 = await api.search(
      '커피유야',
      language: 'kr',
    );
    // return searchResults;
    print(searchResults1.results.first.geometry?.location.lat);
    print(searchResults1.results.first.geometry?.location.lng);

    final searchResults2 = await api.search(
      '경상북도 포항시 북구 천마로 46번길 28-22',
      language: 'kr',
    );
    print(searchResults2.results.first.geometry?.location.lat);
    print(searchResults2.results.first.geometry?.location.lng);

    Point from = Point((searchResults1.results.first.geometry?.location.lat)as num, (searchResults1.results.first.geometry?.location.lat)as num);
    Point to = Point((searchResults2.results.first.geometry?.location.lat)as num, (searchResults2.results.first.geometry?.location.lat)as num);
    Point randomPoint = Point(-23.54545, -23.898098);

    double distance = util.SphericalUtils.computeDistanceBetween(from, to);
    print('Distance: $distance meters');

    // double heading = util.SphericalUtils.computeHeading(from, to);
    // print('Heading: $heading degrees');
    //
    // double angle = util.SphericalUtils.computeAngleBetween(from, to);
    // print('Angle: $angle degrees');
    //
    // double distanceToAB = util.PolyUtils.distanceToLine(randomPoint, from, to);
    // print('Distance to Line: $distanceToAB meters');

    /// Distance: 1241932.6430813475
    /// Heading: 26.302486345342523
    /// Angle: 0.19493500057547358
    /// Distance to Line: 3675538.1518512294

    /// See grid path on: https://developers.google.com/maps/documentation/utilities/polylinealgorithm

    // List<Point> path = util.PolyUtils.decode(
    //     'wjiaFz`hgQs}GmmBok@}vX|cOzKvvT`uNutJz|UgqAglAjr@ijBz]opA|Vor@}ViqEokCaiGu|@byAkjAvrMgjDj_A??ey@abD');
    //
    // print('path size length: ${path.length}');
    //
    // List<Point> simplifiedPath = util.PolyUtils.simplify(path, 5000);
    // String simplifiedPathEncoded = util.PolyUtils.encode(simplifiedPath);
    //
    // print('simplified path: $simplifiedPathEncoded');
    // print('path size simplified length: ${simplifiedPath.length}');
    // /// Example by: https://github.com/nicolascav
    // Point point = Point(-31.623060136389135, -60.68669021129609);

    // /// Triangle
    // List<Point> polygon = [
    //   Point(-31.624115, -60.688734),
    //   Point(-31.624115, -60.684657),
    //   Point(-31.621594, -60.686717),
    //   Point(-31.624115, -60.688734),
    // ];
    //
    // bool contains = util.PolyUtils.containsLocationPoly(point, polygon);
    // print('point is inside polygon?: $contains');
  }
}

