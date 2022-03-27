import 'package:flutter/material.dart';

class Player extends StatelessWidget {
  final VoidCallback stopPlaying, startPlay, upload;
  final bool success, playing;

  // ignore: use_key_in_widget_constructors
  const Player(this.startPlay, this.stopPlaying, this.success, this.upload,
      this.playing);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        success
            ? Text(
                'Upload Ready!',
                style: TextStyle(color: Colors.white, fontSize: 20),
              )
            : SizedBox(
                height: 20,
              ),
        SizedBox(
          height: 20,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FloatingActionButton(
              onPressed: success ? startPlay : (() {}),
              child: playing
                  ? Icon(
                      Icons.pause,
                      color: Colors.white,
                    )
                  : Icon(Icons.play_arrow_rounded, color: Colors.white),
              backgroundColor: Colors.blue,
              heroTag: "btn1",
            ),
            SizedBox(
              width: 16.0,
            ),
            FloatingActionButton(
              onPressed: success ? stopPlaying : () {},
              child: Icon(Icons.stop, color: Colors.white),
              backgroundColor: Colors.blue,
              heroTag: 'btn2',
            ),
          ],
        ),
        SizedBox(
          height: 30,
        ),
        ElevatedButton(
            onPressed: success ? upload : () {}, child: Text("Upload"))
      ],
    );
  }
}
