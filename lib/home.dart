import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:google_geocoding_api/google_geocoding_api.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_maps_utils/google_maps_utils.dart' as util;
import 'dart:math';

import 'package:native_exif/native_exif.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool textScanning = false;
  XFile? imageFile;
  String scannedText = '';
  Exif? exif;
  ExifLatLong? coordinates;

  @override
  void initState() {
    super.initState();
  }

  void getImage([ImageSource source = ImageSource.gallery]) async {
    final pickedImage = await ImagePicker().pickImage(source: source);
    try {
      if (pickedImage != null) {
        textScanning = true;
        imageFile = pickedImage;
        exif = await Exif.fromPath(pickedImage.path);
        coordinates = await exif!.getLatLong();
        setState(() {
        });
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
    // finally {
    //   tags.forEach((key, value) {
    //     print({"$key":"$value"});
    //     mTags.addAll({"$key":"$value"});
    //   });
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

    setState(() {
    });
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
              getUserCurrentLocation().then((value) async {
                print(value.latitude.toString() + " " +
                    value.longitude.toString());
              });
            },
            icon: const Icon(Icons.my_location),
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
                    child: Text(
                      '$scannedText\n$coordinates',
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

  //유저의 현재 위치
  Future<Position> getUserCurrentLocation() async {
    await Geolocator.requestPermission().then((value){
    }).onError((error, stackTrace) async {
      await Geolocator.requestPermission();
      print("ERROR"+error.toString());
    });
    return await Geolocator.getCurrentPosition();
  }

  //1번 주소 --> 경도, 위도 추출
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

    //2번 주소 --> 경도, 위도 추출
    final searchResults2 = await api.search(
      '경상북도 포항시 북구 천마로 46번길 28-22',
      language: 'kr',
    );
    print(searchResults2.results.first.geometry?.location.lat);
    print(searchResults2.results.first.geometry?.location.lng);

    //두 지점 사이 거리 계산
    Point from = Point((searchResults1.results.first.geometry?.location.lat)as num, (searchResults1.results.first.geometry?.location.lat)as num);
    Point to = Point((searchResults2.results.first.geometry?.location.lat)as num, (searchResults2.results.first.geometry?.location.lat)as num);

    double distance = util.SphericalUtils.computeDistanceBetween(from, to);
    print('Distance: $distance meters');
  }
}

