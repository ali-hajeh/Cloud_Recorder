import 'dart:async';
import 'package:cloud_audio/file_list.dart';
import 'package:cloud_audio/player.dart';
import 'package:cloud_audio/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:breathing_collection/breathing_collection.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

// import 'html_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Cloud Audio",
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final _player = FlutterSoundPlayer();

  String? _finalPath = '';

  int second = 0, minute = 0, hour = 0;
  String dSecond = '00', dMinute = '00', dHour = '00';

  bool _started = false;
  bool _isRecording = false;
  bool _success = false;

  Timer? timer;

  void uploadMain() async {
    if (!(await Util.checkAuthorized())) {
      Util.show(context);
    } else {
      Util.upload(_finalPath!);
    }
  }

  Future<void> initRecorder() async {
    await Permission.microphone.request();
    if (await Permission.microphone.isDenied) {
      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    super.initState();
    initRecorder();
    Util.createDirectory();
    Util.initDrop();
  }

  Future<void> startPlay() async {
    if (_player.isPaused) {
      await _player.resumePlayer();
    } else if (_player.isPlaying) {
      _player.pausePlayer();
    } else {
      await _player.openPlayer();
      await _player.startPlayer(fromURI: _finalPath!, codec: Codec.aacMP4);
    }
    setState(() {});
  }

  Future<void> pausePlaying() async {
    if (!_player.isStopped) {
      await _player.stopPlayer();
      setState(() {});
    }
  }

  void _stop() {
    timer!.cancel();
    if (!_recorder.isPaused) {
      _recorder.pauseRecorder();
    }
    setState(() {
      _started = false;
    });
  }

  Future<void> startRec() async {
    if (await File(_finalPath!).exists() &&
        !_recorder.isPaused &&
        !(await Util.fileExists(_finalPath!))) {
      File(_finalPath!).delete();
    }
    _finalPath = '';
    _player.closePlayer();
    setState(() {
      _isRecording = true;
    });
    if (!_recorder.isPaused) {
      _recorder.openRecorder();
      var now = DateTime.now();
      String name =
          '${now.year}-${now.month}-${now.day} at ${now.hour}.${now.minute}.${now.second}';
      _recorder.startRecorder(
          toFile: '${await Util.getDirectory()}/$name.aac',
          codec: Codec.aacMP4);
    } else {
      _recorder.resumeRecorder();
    }
  }

  Future<void> stopRec() async {
    if (!_recorder.isStopped) {
      _finalPath = await _recorder.stopRecorder();
    }
    await _recorder.closeRecorder();
  }

  Future<void> saveRec() async {
    await stopRec();
    await Util.savePath(_finalPath);
    Util.newName(context, _finalPath!);
    _reset(0);
    _success = true;
  }

  void _reset(int flag) {
    _player.stopPlayer();
    _success = false;
    if (timer != null) {
      timer!.cancel();
    }
    stopRec();
    setState(() {
      second = 0;
      minute = 0;
      hour = 0;

      dMinute = '00';
      dHour = '00';
      dSecond = '00';

      _started = false;
      _isRecording = false;
    });
    if (flag == 1) {
      if (_isRecording || _recorder.isStopped) {
        Fluttertoast.showToast(msg: 'Recording discarded');
      }
    }
  }

  void _start() {
    _started = true;
    if (timer == null || !timer!.isActive) {
      startRec();
      timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
        int lSecond = second + 1;
        int lMinute = minute;
        int lHour = hour;

        if (lSecond > 59) {
          if (lMinute > 59) {
            lHour++;
            lMinute = 0;
          } else {
            lMinute++;
          }
          lSecond = 0;
        }
        setState(() {
          second = lSecond;
          minute = lMinute;
          hour = lHour;

          dSecond = second >= 10 ? ('$second') : ('0$second');
          dHour = hour >= 10 ? ('$hour') : ('0$hour');
          dMinute = minute >= 10 ? ('$minute') : ('0$minute');
        });
      });
    } else {
      _started = false;
      timer!.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Color.fromARGB(255, 39, 127, 168),
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 40.0,
                  ),
                  Text(
                    'Cloud Recorder',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    width: 8.0,
                  ),
                  PopupMenuButton(
                    onSelected: (value) async {
                      if (value.toString() == 'un') {
                        Util.clearToken();
                        _reset(0);
                      }
                    },
                    color: Colors.white,
                    itemBuilder: (BuildContext cntxt) {
                      return const [
                        PopupMenuItem(
                          child: Text('Unlink'),
                          value: 'un',
                        )
                      ];
                    },
                  )
                ],
              ),
            ),
            Container(
              alignment: Alignment.center,
              child: RawMaterialButton(
                  fillColor: Colors.white,
                  shape: StadiumBorder(
                      side: BorderSide(
                    color: Colors.grey,
                  )),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'Check Saved Recordings',
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ),
                  onPressed: () {
                    _reset(0);
                    setState(() {
                      _success = false;
                    });
                    _finalPath = '';
                    if (!_player.isStopped) {
                      _player.stopPlayer();
                    }

                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const FileList()));
                  }),
            ),
            SizedBox(
              height: 20,
            ),
            Center(
              child: Text(
                '$dHour:$dMinute:$dSecond',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 80.0,
                    fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              height: 200,
              width: MediaQuery.of(context).size.width - 10,
              decoration: BoxDecoration(
                  color: Color.fromARGB(255, 66, 80, 126),
                  borderRadius: BorderRadius.circular(8.0)),
              child: Center(
                  child: Player(startPlay, pausePlaying, _success, uploadMain,
                      _player.isPlaying)),
            ),
            SizedBox(
              height: 20.0,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: RawMaterialButton(
                    onPressed: (!_started) ? _start : _stop,
                    shape: const StadiumBorder(
                        side: BorderSide(color: Colors.blue)),
                    child: Text(
                      (!_started) ? 'Start' : 'Pause',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    fillColor: Color.fromRGBO(126, 132, 214, 2000),
                  ),
                ),
                SizedBox(
                  width: 12.0,
                ),
                _isRecording
                    ? BreathingGlowingButton(
                        icon: Icons.stop,
                        glowColor: Colors.white,
                        buttonBackgroundColor: Colors.red,
                        iconColor: Colors.white,
                        onTap: saveRec,
                        height: 35.0,
                        width: 35.0,
                      )
                    : SizedBox(
                        width: 35.0,
                      ),
                SizedBox(
                  width: 12.0,
                ),
                Expanded(
                  child: RawMaterialButton(
                    onPressed: () {
                      _reset(1);
                    },
                    fillColor: Colors.blue,
                    shape: const StadiumBorder(
                        side: BorderSide(color: Colors.blue)),
                    child: Text(
                      'Discard',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      )),
    );
  }
}
