import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

//final fileUrl = 'https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/Common-Credentials/10-million-password-list-top-1000.txt';
final fileUrl = 'https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/Common-Credentials/10-million-password-list-top-1000000.txt';
//final fileUrl = '';
//final fileUrl = 'https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/Common-Credentials/10-million-password-list-top-10000.txt';

var dio = Dio();

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Download known password list '),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  double _progress = 0;
  bool _flag = false; // background color download button
  TextEditingController passwordController = TextEditingController();
  TextEditingController resultController = TextEditingController();

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _doProgress(double data) {
    setState(() {
      _progress = data;
      print('doProgress data: ' + data.toString());
    });
  }

  String _getFilenameFromUrl(String url) {
    final String predefinedFileName = 'file.dat';
    try {
      return url
          .split('/')
          .last;
    } catch (e) {
      return predefinedFileName;
    }
  }

  bool _fileExists(String filePath) {
    return File(filePath).existsSync();
  }

  Future<bool> _checkPassword(String password) async {
    // before run this method you have to check if the fileUrl ist existing !!
    bool pwInFile = false;
    final appStorage = await getApplicationDocumentsDirectory();
    print('appStorage: ' + appStorage.toString());
    String passwordListName =
        appStorage.path + '/' +
            _getFilenameFromUrl(fileUrl);
    //var file = File(passwordListName);

    await new File(passwordListName)
        .openRead()
        .transform(utf8.decoder)
        .transform(new LineSplitter())
        .forEach((l) {
      if (l == password) {
        pwInFile = true;
        print('### PW found ###');
        return;
      }
    }
    );
    // at this point the whole file was searched and not found
    return pwInFile;
  }

  Future openFile({required String url, String? fileName}) async {
    // get filename from url if no fileName was given
    final name = fileName ?? url
        .split('/')
        .last;
    print('name: ' + name);
    // get fileName from declaration
    //final file = await downloadFile(url, fileName!);
    // get fileName from url
    final file = await downloadFile(url, name);

    if (file == null) return;
    print('Path:  ${file.path}');
    //OpenFile.open(filePath);
  }

  Future<File?> downloadFile(String url, String name) async {
    _progress = 0;
    final appStorage = await getApplicationDocumentsDirectory();
    final file = File('${appStorage.path}/$name');
    try {
      final response = await Dio().get(
        url,
        onReceiveProgress: showDownloadProgress,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          receiveTimeout: 0,
          headers: {HttpHeaders.acceptEncodingHeader: "*"}, // disable gzip
        ),

      );
      final raf = file.openSync(mode: FileMode.write);
      raf.writeFromSync(response.data);
      await raf.close();
      return file;
    } catch (e) {
      return null;
    }
  }

  Future download2(Dio dio, String url, String savePath) async {
    try {
      Response response = await dio.get(
        url,
        onReceiveProgress: showDownloadProgress,
        //Received data with List<int>
        options: Options(
            responseType: ResponseType.bytes,
            followRedirects: false,
            validateStatus: (status) {
              return status! < 500;
            }),
      );
      print(response.headers);
      File file = File(savePath);
      var raf = file.openSync(mode: FileMode.write);
      // response.data is List<int> type
      raf.writeFromSync(response.data);
      await raf.close();
    } catch (e) {
      print(e);
    }
  }

  void showDownloadProgress(received, total) {
    // if using this option no compression is done:
    // headers: {HttpHeaders.acceptEncodingHeader: "*"}, // disable gzip
    if (total != -1) {
      _doProgress(received / (total));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[

            ElevatedButton(
              onPressed: () async {
                final appStorage = await getApplicationDocumentsDirectory();
                print('appStorage: ' + appStorage.toString());
                String passwordListName =
                    appStorage.path + '/' +
                        _getFilenameFromUrl(fileUrl);
                bool fileExists = _fileExists(passwordListName);
                print('file: ' + passwordListName +
                    ' is existing: ' + fileExists.toString());
                if (fileExists) showAlertDialog(context);

                // get file size of download
                print('url: ' + fileUrl);
                var url = Uri.parse(fileUrl);

                //http.Response r = await http.get(url)
                http.Response r = await http.head(url,
                    headers: {
                    });
                //http.Response r = await http.get(url);
                var urlFileSize = r.headers["content-length"];
                print('urlFileSize: ' + urlFileSize.toString());
              },
              child: Text('Download password list check'),
            ),

            ElevatedButton.icon(
              //RaisedButton.icon(
                onPressed: () {
                  openFile(
                    url: fileUrl,
                    // wenn die url den filename enthält...
                    //fileName: 'top10.txt',
                  );
                  setState(() {});
                },
                icon: Icon(
                  Icons.file_download,
                  color: Colors.white,
                ),
                // https://stackoverflow.com/questions/66835173/how-to-change-background-color-of-elevated-button-in-flutter-from-function
                // https://stackoverflow.com/a/67567397/8166854
                style: ElevatedButton.styleFrom(
                  primary: _flag ? Colors.red : Colors.green,
                ),
                //color: Colors.green,
                //textColor: Colors.white,
                label: Text('Download password list')),
            CircularProgressIndicator(
              strokeWidth: 4,
              backgroundColor: Colors.red,
              valueColor: new AlwaysStoppedAnimation<Color>(Colors.green),
              value: _progress,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter a password',
                ),
              ),
            ),
            ElevatedButton(
                onPressed: () async {
                  resultController.text = '';
                  String password = passwordController.text;
                  // first check that password list is available
                  final appStorage = await getApplicationDocumentsDirectory();
                  print('appStorage: ' + appStorage.toString());
                  String passwordListName =
                      appStorage.path + '/' +
                          _getFilenameFromUrl(fileUrl);
                  bool fileExists = _fileExists(passwordListName);
                  print('file: ' + passwordListName +
                      ' is existing: ' + fileExists.toString());
                  if (fileExists) {
                    bool passwordInList = await _checkPassword(password);
                    print('passwordInList: ' + passwordInList.toString());
                    if (passwordInList) {
                      resultController.text = 'the entered password is in the list';
                      showAlertDialogBadPassword(context);
                    } else {
                      resultController.text = 'the entered password is NOT in the list';
                    }
                  }
                },
                child: Text('check password')),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: TextField(
                controller: resultController,
                maxLines: 2,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Result of check',
                  labelText: 'Result of check',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // source: https://stackoverflow.com/a/53844053/8166854
  showAlertDialog(BuildContext context) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("Nein"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
    Widget continueButton = TextButton(
      child: Text("Ja"),
      onPressed: () {
        Navigator.of(context).pop(); // dismiss dialog
        openFile(
          url: fileUrl,
          // wenn die url den filename enthält...
          //fileName: 'top10.txt',
        );
        setState(() {});
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Hinweis: Die Datei existiert"),
      content: Text(
          "Die Datei wurde bereits herunter geladen. Soll die Datei erneut geladen werden?"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );



  }

  showAlertDialogBadPassword(BuildContext context) {
    // set up the buttons
    /*
      Widget cancelButton = TextButton(
        child: Text("Nein"),
        onPressed:  () {
          Navigator.of(context).pop();
        },
      );*/
    Widget continueButton = TextButton(
      child: Text("OK"),
      onPressed: () {
        Navigator.of(context).pop(); // dismiss dialog
        passwordController.text = '';
        setState(() {});
      },
    );


    // set up the AlertDialog
    AlertDialog alertBadPassword = AlertDialog(
      title: Text("Hinweis: Das Passwort ist bekannt"),
      content: Text(
          "Das Password ist weltweit bekannt und kann nicht genutzt werden, bitte wählen Sie ein anderes Passwort aus."),
      actions: [
        //cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alertBadPassword;
      },
    );
  }
}