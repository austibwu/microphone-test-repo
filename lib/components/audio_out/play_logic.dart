// ignore_for_file: avoid_print

import 'package:audiotestproject/components/data/globals.dart';
import 'package:audiotestproject/components/audio_out/wavegenerator/wave_generator.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:io';
import 'package:audiotestproject/components/controls/saving.dart';
import 'package:audiotestproject/components/data/signal_processing.dart';
import 'package:record/record.dart';

/// generates the waveform according to user input, writes to .wav file
Future<void> makeWAV() async {
  outputWave.outputWave = File(outputWave.filePath)..create(recursive: true);

  var generator = WaveGenerator(44100, outputWave.bitDepth);

  // instantiate a Note with given params
  Note note = Note(outputWave.fNought.toDouble(), outputWave.fEnd.toDouble(),
      outputWave.duration.toInt() * 1000, 1, outputWave.isSweep, outputWave.steps);

  List<int> bytes = [];
  await outputWave.outputWave.writeAsString(''); //  clears existing file
  try {
    // stream of audio bytes
    await for (int byte in generator.generate(note)) {
      bytes.add(byte);
    }
    // writes byte stream to .wav
    await outputWave.outputWave.writeAsBytes(bytes, mode: FileMode.writeOnly);
    // connects to audio player
    await outputWave.player.setSource(DeviceFileSource(outputWave.filePath));
  } catch (err) {
    throw ('caught error while writing to .wav: $err');
  } finally {
    playAndRecord();
  }
  spectrumInfo.fundamental = outputWave.fNought.toDouble();
  print('from makewave ${spectrumInfo.fundamental}');
}

/// simultaneously initiates, ends the audio output stream and recording.
/// does not control for latency
void playAndRecord() async {
  final AudioRecorder audioRecorder = AudioRecorder();
  String recordedPath = '${appCacheDir.path}/wave_in.wav';

  // final AudioRecorder streamRecorder = AudioRecorder(); // to delete:

  // macOS: recorder interface ignores all config settings except for encoding specification
  // iOS: seems to work correctly.
  int sampleRate = 48000;  // ignored on macOS.
  var myconfig = RecordConfig(
    encoder: AudioEncoder.wav,
    sampleRate: sampleRate,
    bitRate: sampleRate * 16,
    numChannels: 2,
  );

  try {
    outputWave.player.resume(); // begin streaming generated audio
    // print('Recording now'); // debugging marker
    spectrumIsLoaded.value = false;
    // band-aid solution > recording in float32 bitdepth to file
    audioRecorder.start(myconfig, path: recordedPath);

    // recording in 16bit PCM to Stream. broadcast stream returns bytelist 10 times per second, 100ms
    // maybe use this instead of writing to .wav and reading it back, but this is limited to 16bit audio resolution.
    // Stream<Uint8List> broadcast = await streamRecorder.startStream(RecordConfig(
    //   encoder: AudioEncoder.pcm16bits,
    //   sampleRate: 48000,
    //   bitRate: sampleRate * 16,
    //   numChannels: 1,
    // ));

    // processStream(broadcast); // ignore. stream related.
  } catch (e, s) {
    print(e);
    print(s);
  }

  outputWave.player.onPlayerComplete.listen((event) async {
    outputWave.player.release();
    // streamRecorder.stop().then((value) {
    //   print(value);
    // });

    await audioRecorder.stop().then((value) {
      // print('Recorded file path: $value');
      readWAV(recordedPath);
      spectrumIsLoaded.value = true;
      return;
    });
  });
}
