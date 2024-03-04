import 'package:audiotestproject/components/data/globals.dart';
import 'package:flutter/material.dart';
import 'package:audiotestproject/components/audio_out/play_logic.dart';
import 'package:audiotestproject/components/audio_out/audioplayer_controls.dart';
import 'package:audioplayers/audioplayers.dart';

/// widget for the 'play' button and dispose button. 
/// TODO: replace dispose button with a pause or stop... or something else
class PlayButton extends StatefulWidget {
  const PlayButton({super.key}); // ?

  @override
  State<PlayButton> createState() => PlayButtonState();
}

class PlayButtonState extends State<PlayButton> {
  @override
  Widget build(context) {
    return Transform.scale(
      scale: 1.2,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(
          onPressed: () async {
            if (outputWave.player.state == PlayerState.playing) {
              return;
            }
            await makeWAV();
            testNotifier.onChanged();
          },
          tooltip: 'Play Sound',
          icon: const Icon(Icons.play_arrow),
        ),
        IconButton(
            onPressed: () => disposefunc(),
            tooltip: 'dispose',
            icon: const Icon(Icons.delete)),
      ]),
    );
  }
}
