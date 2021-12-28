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

  double _progress = 0;
  bool _flag = false; // background color download button
  TextEditingController passwordController = TextEditingController();
  TextEditingController resultController = TextEditingController();

  void _doProgress(double data) {
    setState(() {
      _progress = data;
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
    String passwordListName =
        appStorage.path + '/' +
            _getFilenameFromUrl(fileUrl);

    await new File(passwordListName)
        .openRead()
        .transform(utf8.decoder)
        .transform(new LineSplitter())
        .forEach((l) {
      if (l == password) {
        pwInFile = true;
        // print('### PW found ###');
        return;
      }
    }
    );
    // at this point the whole file was searched and not found
    return pwInFile;
  }

  Future openFileO({required String url, String? fileName}) async {
    // get filename from url if no fileName was given
    final name = fileName ?? url
        .split('/')
        .last;
    // get fileName from declaration
    //final file = await downloadFile(url, fileName!);
    // get fileName from url
    final file = await downloadFile(url, name);

    if (file == null) return;
    resultController.text = 'The file ' + url + ' was downloaded';
    //OpenFile.open(filePath);
  }

  Future downloadFile(String url, String? fileName) async {
    _progress = 0;
    // get filename from url if no fileName was given
    final name = fileName ?? url
        .split('/')
        .last;
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
      resultController.text = 'The file ' + url + ' was downloaded';
      return;
    } catch (e) {
      return;
    }
  }

  Future<File?> downloadFile_org(String url, String name) async {
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
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final appStorage = await getApplicationDocumentsDirectory();
                String passwordListName =
                    appStorage.path + '/' +
                        _getFilenameFromUrl(fileUrl);
                bool fileExists = _fileExists(passwordListName);
                resultController.text = 'file: ' + passwordListName +
                    ' is existing: ' + fileExists.toString();
                if (fileExists) {
                  showAlertDialog(context); }
                else {
                  // direct download
                  resultController.text = 'start download the file ' + fileUrl;
                  downloadFile(fileUrl, '');
                  setState(() {});
                };

                // get file size of download
                var url = Uri.parse(fileUrl);
                //http.Response r = await http.get(url)
                http.Response r = await http.head(url,
                    headers: {
                    });
                //http.Response r = await http.get(url);
                var urlFileSize = r.headers["content-length"];
                resultController.text += ('/nurlFileSize: ' + urlFileSize.toString());

              },
              child: Text('Download password list check'),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
                onPressed: () async {
                  await downloadFile(fileUrl, '');
                  setState(() {});
                },
                icon: Icon(
                  Icons.file_download,
                  color: Colors.white,
                ),
                style: ElevatedButton.styleFrom(
                  primary: _flag ? Colors.red : Colors.green,
                ),
                label: Text('Download password list')),
            SizedBox(height: 20),
            CircularProgressIndicator(
              strokeWidth: 4,
              backgroundColor: Colors.red,
              valueColor: new AlwaysStoppedAnimation<Color>(Colors.green),
              value: _progress,
            ),
            SizedBox(height: 20),
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
            SizedBox(height: 20),
            ElevatedButton(
                onPressed: () async {
                  resultController.text = '';
                  String password = passwordController.text;
                  // first check that password list is available
                  final appStorage = await getApplicationDocumentsDirectory();
                  String passwordListName =
                      appStorage.path + '/' +
                          _getFilenameFromUrl(fileUrl);
                  bool fileExists = _fileExists(passwordListName);
                  if (fileExists) {
                    bool passwordInList = await _checkPassword(password);
                    //print('passwordInList: ' + passwordInList.toString());
                    if (passwordInList) {
                      resultController.text = 'the entered password is in the list';
                      showAlertDialogBadPassword(context);
                    } else {
                      resultController.text = 'the entered password is NOT in the list';
                    }
                  } else {
                    resultController.text = 'The file ' + passwordListName + ' is NOT existing.';
                  }
                },
                child: Text('check password')),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: TextField(
                controller: resultController,
                maxLines: 6,
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
      onPressed: () async {
        Navigator.of(context).pop(); // dismiss dialog
        resultController.text = 'start download the file ' + fileUrl;
        downloadFile(fileUrl, '');
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