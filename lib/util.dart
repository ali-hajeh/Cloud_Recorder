import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dropbox_client/dropbox_client.dart';
import 'package:path/path.dart' as path;
import 'html_manager.dart';

const String getIdKey = "ID";
const String getFilesKey = "List_Paths";
const String tokenKey = 'token_key';
Future<String> get _directory async {
  return '${(await getApplicationDocumentsDirectory()).path}/recordings';
}

class Util {
  static final Future<SharedPreferences> _prefs =
      SharedPreferences.getInstance();

  static Future<void> initDrop() async {
    await Dropbox.init('ih9mqv2jovbnyji', 'ih9mqv2jovbnyji', 'zdd8vuhnis6ot0p');
  }

  static Future<bool> checkAuthorized() async {
    SharedPreferences prefs = await _prefs;
    String temp = prefs.getString(tokenKey) ?? '';
    if (temp != '') {
      Dropbox.authorizeWithAccessToken(temp);
    }

    final token = await Dropbox.getAccessToken();
    if (token != null && token.isNotEmpty) {
      prefs.setString(tokenKey, token);
      return true;
    }
    return false;
  }

  static Future<void> clearToken() async {
    Dropbox.unlink();
    SharedPreferences prefs = await _prefs;
    await prefs.setString(tokenKey, '');
    _clearUploads();
  }

  static Future<void> generateNewAccess() async {
    SharedPreferences prefs = await _prefs;
    if (await checkAuthorized()) {
      return;
    } else {
      await Dropbox.authorize();
      await routineUpCheck();
      String token = await Dropbox.getAccessToken() ?? '';
      prefs.setString(tokenKey, token);
    }
  }

  static Future<int> getID() async {
    final SharedPreferences prefs = await _prefs;
    int id = prefs.getInt(getIdKey) ?? 1;
    prefs.setInt(getIdKey, id + 1);
    return id;
  }

  static Future<String> getDirectory() async {
    return await _directory;
  }

  static void createDirectory() async {
    bool isDirectoryCreated = await Directory(await _directory).exists();
    if (!isDirectoryCreated) {
      Directory(await _directory).create();
    }
  }

  static void upload(String filePath) async {
    SharedPreferences prefs = await _prefs;
    String temp = prefs.getString(tokenKey) ?? '';
    final pathOfFile = '/' + path.basename(filePath);
    final dropBox = DropBox(path: pathOfFile, dropBoxToken: temp);
    final result = await dropBox.upload(fileToUpload: File(filePath));
    if (result.toString() == 'successfully uploaded') {
      Util.setUploadState(filePath, true);
      Fluttertoast.showToast(msg: 'Successfully Uploaded');
    } else {
      Fluttertoast.showToast(msg: 'Unkown error occured');
    }
  }

  static Future<void> savePath(String? filePath) async {
    String tempName = path.basename(filePath!);

    if (filePath != '' && !(await fileExists(filePath))) {
      Map<String, dynamic> temp = {
        'name': tempName,
        'id': await getID(),
        'uploaded': false,
        'path': filePath,
      };
      String json = jsonEncode(temp);
      final SharedPreferences prefs = await _prefs;
      List<String> files = [];
      files = prefs.getStringList(getFilesKey) ?? [];
      files.add(json);
      prefs.setStringList(getFilesKey, files);
    }
    _routineCheckup();
  }

  static Future<void> _routineCheckup() async {
    var temp = (await getApplicationDocumentsDirectory()).listSync();
    for (var x in temp) {
      String temp = x.toString();
      if (!(await fileExists(temp))) {
        var tempList = temp.split('.');
        if (tempList[tempList.length - 1] == 'aac') {
          x.delete();
        }
      }
    }
  }

  static Future<List<Map<String, dynamic>>> getFiles() async {
    final SharedPreferences prefs = await _prefs;
    List<String> temp = prefs.getStringList(getFilesKey) ?? [];
    List<Map<String, dynamic>> temp2 = _decode(temp);
    // temp2.sort(((a, b) => b['name'].compareTo(a['name'])));
    return temp2;
  }

  static Future<bool> fileExists(String path) async {
    SharedPreferences prefs = await _prefs;
    var temp = _decode(prefs.getStringList(getFilesKey) ?? []);
    for (var x in temp) {
      if (x['path'] == path) {
        return true;
      }
    }
    return false;
  }

  static List<Map<String, dynamic>> _decode(List<String> temp) {
    List<Map<String, dynamic>> temp2 = [];
    for (var x in temp) {
      temp2.add(jsonDecode(x));
    }
    return temp2;
  }

  static List<String> _encode(List<Map<String, dynamic>> temp) {
    List<String> temp2 = [];
    for (var x in temp) {
      temp2.add(jsonEncode(x));
    }
    return temp2;
  }

  static void setUploadState(String path, bool v) async {
    var temp = await getFiles();
    for (var x in temp) {
      if (x['path'] == path) {
        x['uploaded'] = v;
      }
    }
    SharedPreferences prefs = await _prefs;
    prefs.setStringList(getFilesKey, _encode(temp));
  }

  static void deleteRec(String path) async {
    SharedPreferences prefs = await _prefs;
    var temp = _decode(prefs.getStringList(getFilesKey) ?? []);
    Map<String, dynamic> v = {};
    for (var x in temp) {
      if (x['path'] == path) {
        v = x;
        break;
      }
    }
    temp.remove(v);
    prefs.setStringList(getFilesKey, _encode(temp));
    if (await File(path).exists()) {
      File(path).delete();
    }
  }

  static void setName(String name, String filePath) async {
    SharedPreferences prefs = await _prefs;
    var temp = await getFiles();
    for (int x = 0; x < temp.length; x++) {
      if (temp[x]['path'] == filePath) {
        temp[x]['name'] = name;
        prefs.setStringList(getFilesKey, _encode(temp));
      }
    }
  }

  static void newName(BuildContext context, String path) {
    showDialog(
        context: context,
        builder: (BuildContext cntxt) {
          return AlertDialog(
            content: TextField(
              onChanged: (value) => setName(value, path),
              decoration: InputDecoration(hintText: "Name (Can be left empty)"),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(cntxt), child: Text("Done"))
            ],
          );
        });
  }

  static void show(BuildContext cntxt) async {
    await showDialog(
        context: cntxt,
        barrierDismissible: true,
        builder: (BuildContext cntxt) {
          return AlertDialog(
            title: Text(
                "You need to log in to dropbox before you can upload audio"),
            content: Text(
                'If you were previously logged in, the session must have expired.'),
            actions: [
              TextButton(
                  onPressed: () async {
                    await Util.generateNewAccess();
                    Navigator.pop(cntxt);
                  },
                  child: Text(
                    "Log in",
                  )),
              TextButton(
                  onPressed: () {
                    Navigator.pop(cntxt);
                  },
                  child: Text("Dismiss"))
            ],
          );
        });
  }

  static Future<void> routineUpCheck() async {
    if (!(await checkAuthorized())) {
      return;
    }
    SharedPreferences prefs = await _prefs;
    var files = await getFiles();
    for (int i = 0; i < files.length; i++) {
      String? filePath = path.basename(files[i]['path']);
      String? temp = await Dropbox.getTemporaryLink('/$filePath');
      if (temp != null && temp != '') {
        files[i]['uploaded'] = true;
      } else {
        files[i]['uploaded'] = false;
      }
    }
    await prefs.setStringList(getFilesKey, _encode(files));
  }

  static void _clearUploads() async {
    SharedPreferences prefs = await _prefs;
    var temp = await getFiles();
    for (int i = 0; i < temp.length; i++) {
      temp[i]['uploaded'] = false;
    }
    await prefs.setStringList(getFilesKey, _encode(temp));
  }
}
