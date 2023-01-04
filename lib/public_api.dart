import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as dev;

class PublicAPI extends StatefulWidget{
  @override
  _PublicAPIState createState() => _PublicAPIState();
}

class _PublicAPIState extends State<PublicAPI> {

  TextEditingController controller = TextEditingController();
  List<dynamic> list = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Expanded(
                    child: TextField(controller: controller,)
                ),
                ElevatedButton(
                    onPressed: () {
                      Map<String, String> params = {
                        'confmKey': 'devU01TX0FVVEgyMDIzMDEwNDExNTQxNDExMzM5OTk=',
                        'currentPage': '1',
                        'countPerPage': '10',
                        'keyword': controller.text,
                        'resultType': 'json',
                      };
                      http.post(
                        //주소
                        Uri.parse('https://business.juso.go.kr/addrlink/addrLinkApi.do'),
                        body: params,
                        headers: {
                          'content-type': 'application/x-www-form-urlencoded',
                        }
                      )
                        .then((response) {
                          var json = jsonDecode(response.body);
                          setState(() {
                            list = json['results']['juso'];
                            
                          });
                        } )
                        .catchError((error) {
                          print(error);
                      } );
                    },
                    child: Text("검색"))
              ],
            ),
            Expanded(
                child: (
                ListView.separated(itemBuilder: (context, index) {
                  return Text('${list [ index ] ['roadAddr']}');
                }, separatorBuilder: (context, index) {
                  return Divider();
                }, itemCount: list.length)
                ))
          ],
        ),
      ),
    );
  }
}
