import 'dart:async';

import 'package:flutter_sound/flutter_sound.dart';

import 'package:cloud_audio/util.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class FileList extends StatefulWidget {
  const FileList({Key? key}) : super(key: key);

  @override
  State<FileList> createState() => FileListState();
}

class FileListState extends State<FileList> {
  int _playing = -1;
  String _currentTrack = '';
  final _player = FlutterSoundPlayer();

  List<Map<String, dynamic>> _list = [];

  void initList() async {
    var temp = await Util.getFiles();
    setState(() {
      _list = temp;
    });
  }

  @override
  void initState() {
    super.initState();
    initCheck();
  }

  void initCheck() async {
    await Util.routineUpCheck();
  }

  Future<void> startPlay() async {
    if (_player.isPaused && _player.isOpen() && !_player.isStopped) {
      await _player.resumePlayer();
    } else if (_player.isPlaying && _player.isOpen()) {
      await _player.pausePlayer();
    } else {
      await _player.openPlayer();
      await _player.startPlayer(fromURI: _currentTrack, codec: Codec.aacMP4);
    }
  }

  @override
  Widget build(BuildContext context) {
    initList();
    return WillPopScope(
      onWillPop: () async {
        _player.stopPlayer();
        return true;
      },
      child: Scaffold(
        backgroundColor: Color.fromARGB(255, 39, 127, 168),
        body: SafeArea(
            child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    BackButton(
                      color: Colors.white,
                      onPressed: () {
                        if (!_player.isStopped) {
                          _player.stopPlayer();
                        }
                        Navigator.pop(context);
                      },
                    ),
                    SizedBox(
                      width: 30.0,
                    ),
                    Text(
                      "Saved Recordings",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Divider(
                  thickness: 2,
                  color: Colors.blue,
                ),
                _list.isNotEmpty
                    ? Expanded(
                        child: ListView.builder(
                            scrollDirection: Axis.vertical,
                            shrinkWrap: true,
                            itemCount: _list.length,
                            itemBuilder: (context, index) {
                              bool uploaded = _list[index]['uploaded'];
                              return Card(
                                child: ListTile(
                                  title: Text(
                                    '${_list[index]['name']}',
                                    style: TextStyle(color: Colors.blueGrey),
                                  ),
                                  trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        uploaded
                                            ? Icon(Icons.check)
                                            : SizedBox(
                                                width: 1.6,
                                              ),
                                        PopupMenuButton(
                                          onSelected: (value) async {
                                            if (value.toString() == 'up') {
                                              if (!(await Util
                                                  .checkAuthorized())) {
                                                Util.show(context);
                                              } else {
                                                var temp = _list[index];
                                                if (!temp['uploaded']) {
                                                  Util.upload(
                                                      _list[index]['path']);
                                                } else {
                                                  Fluttertoast.showToast(
                                                      msg:
                                                          'Recording Already uploaded');
                                                }
                                              }
                                            } else if (value.toString() ==
                                                'del') {
                                              showDialog(
                                                  context: context,
                                                  barrierDismissible: true,
                                                  builder:
                                                      (BuildContext cntxt) {
                                                    return AlertDialog(
                                                      title: Text(
                                                          "Are you sure you want to delete this reocrding?"),
                                                      actions: [
                                                        TextButton(
                                                            onPressed: () {
                                                              if (_playing ==
                                                                  index) {
                                                                _player
                                                                    .stopPlayer();
                                                              }
                                                              Util.deleteRec(
                                                                  _list[index]
                                                                      ['path']);
                                                              Navigator.pop(
                                                                  cntxt);
                                                            },
                                                            child: Text(
                                                              "Yes",
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .red),
                                                            )),
                                                        TextButton(
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  cntxt);
                                                            },
                                                            child: Text("N0"))
                                                      ],
                                                    );
                                                  });
                                            } else if (value.toString() ==
                                                'ren') {
                                              setState(() {
                                                Util.newName(context,
                                                    _list[index]['path']);
                                              });
                                            }
                                          },
                                          itemBuilder: (BuildContext cntxt) {
                                            return const [
                                              PopupMenuItem(
                                                child: Text('Upload'),
                                                value: 'up',
                                              ),
                                              PopupMenuItem(
                                                child: Text('Rename'),
                                                value: 'ren',
                                              ),
                                              PopupMenuItem(
                                                child: Text(
                                                  'Delete',
                                                  style: TextStyle(
                                                      color: Colors.red),
                                                ),
                                                value: 'del',
                                              )
                                            ];
                                          },
                                        ),
                                      ]),
                                  leading: index == _playing
                                      ? Icon(Icons.play_arrow_rounded)
                                      : Icon(Icons.stop_rounded),
                                  onTap: () async {
                                    String temp =
                                        _list[index]['path'] as String;
                                    if (temp != _currentTrack) {
                                      setState(() {
                                        _playing = index;
                                      });
                                      await _player.stopPlayer();
                                      _currentTrack = temp;
                                    }
                                    if (_player.isPaused ||
                                        _player.isStopped ||
                                        !_player.isOpen() ||
                                        !_player.isPlaying) {
                                      _playing = index;
                                    } else {
                                      _playing = -1;
                                    }
                                    startPlay();
                                  },
                                ),
                              );
                            }),
                      )
                    : Column(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height / 3.0,
                          ),
                          Center(
                            child: Text(
                              "No Recirdings Saved",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
              ]),
        )),
      ),
    );
  }
}
