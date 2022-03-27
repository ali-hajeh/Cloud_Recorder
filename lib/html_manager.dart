import 'dart:convert';
import 'dart:io';
import 'package:cloud_audio/util.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class DropBox {
  static final Uri _url =
      Uri.parse("https://content.dropboxapi.com/2/files/upload");

  final String path;
  String _token = '';

  // headers
  late Map<String, String> _headers;

  DropBox({
    required this.path,
    required String dropBoxToken,
  }) {
    _token = dropBoxToken;

    final _args = {
      "path": path,
      "mode": {
        ".tag": 'add',
      },
      "autorename": true,
    };
    _headers = {
      'Authorization': 'Bearer $_token',
      "Content-Type": "application/octet-stream",
      "Dropbox-API-Arg": jsonEncode(_args),
    };
  }

  Future<String?> upload({@required File? fileToUpload, int x = 0}) async {
    final _client = http.Client();

    var filePath = fileToUpload!.path;

    try {
      final bytes = await fileToUpload.readAsBytes();

      final response = await _client.post(_url, body: bytes, headers: _headers);

      if (response.statusCode == 200) {
        return 'successfully uploaded';
      } else {
        if (x == 0) {
          Util.generateNewAccess();
          upload(fileToUpload: fileToUpload, x: 1);
        }
        return ('[ERROR] Failed to upload: $filePath to dropbox!');
      }
    } on http.ClientException catch (ce) {
      return ce.message;
    } catch (e) {
      return e.toString();
    } finally {
      _client.close();
    }
  }
}
