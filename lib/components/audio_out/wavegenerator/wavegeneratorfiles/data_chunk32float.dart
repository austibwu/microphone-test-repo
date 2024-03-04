import 'dart:typed_data';
import 'dart:math';

import 'byte_helpers.dart';
import 'chunk.dart';
import 'format_chunk.dart';
// import 'generator_function.dart';

import '../wave_generator.dart';

class DataChunk32Float implements DataChunk {
  final FormatChunk format;
  final Note note;

  final String _sGroupId = 'data';

  /// FS for pcm float32 is 0<x<1.0, or amplitude of .5
  double clamp(double byte) {
    return byte.clamp(0, 1.0);
  }

  const DataChunk32Float(this.format, this.note);

  @override
  Stream<int> bytes() async* {
    var groupIdBytes = ByteHelpers.toBytes(_sGroupId);
    var bytes = groupIdBytes.buffer.asByteData();

    // Subchunk2ID  >> contains the letters "data"
    for (int i = 0; i < 4; i++) {
      yield bytes.getUint8(i);
    }

    // SubChunk2Size == NumSamples * NumChannels * BitsPerSample/8
    //  This is the number of bytes in the data.
    // length = length of the data chunk
    var byteData = ByteData(4);
    byteData.setUint32(0, length, Endian.little);
    for (int i = 0; i < 4; i++) {
      yield byteData.getUint8(i);
    }

    // Determine when one note ends and the next begins
    // Number of samples per note given by sampleRate * note duration
    // compare against step count to select the correct note
    double fNought = note.fNought;
    double fEnd = note.fEnd;
    bool isSweep = note.isSweep; // default
    int? steps = note.steps; // default, param

    double secDuration = note.msDuration / 1000;

    double stepsize;

    int totalSamples = (secDuration * format.sampleRate).toInt();
    int incrementNoteOnSample;

    if (steps == 0) {
      stepsize = 0;
      incrementNoteOnSample = totalSamples;
    } else {
      stepsize = (fEnd - fNought) / steps; // can be positive or negative
      incrementNoteOnSample = totalSamples ~/ steps;
    }
    // omega = angular frequency of the sine wave, rate of change in sine phase per x
    double omega = fNought * (2 * pi) / format.sampleRate; // for regular sinusoidal tone
    // omega = return sin(theta) > 0 ? 1.0 : -1.0; // square wave
    // theta % (2 * pi); // triangle wave
    double y;
    double sweepRange = fEnd - fNought;
    for (int x = 0; x < totalSamples; x++) {
      // loop to create each sample in the waveform
      if (x > 0 && x % incrementNoteOnSample == 0) {
        fNought += stepsize;
      }
      if (isSweep) {
        // linear sweep, aka chrip
        y = sin(2 *
            pi *
            ((fNought / format.sampleRate) * x +
                (sweepRange / (2 * secDuration * 44100 * 44100)) *
                    x *
                    x));
      } else {
        y = sin(omega * x); // single note or stepwise rise, sinusoidal shape
      }
      double volume = (.5 *
          note.volume);
      // for float32, 1.0 is considered zero dBFS (dB Full Scale).
      double sample = (volume * y);

      var byteData = ByteData(4);
      byteData.setFloat32(0, sample, Endian.little);
      for (int i = 0; i < 4; i++) {
        yield byteData.getInt8(i);
      }
    }

    // If the number of bytes is not word-aligned, ie. number of bytes is odd, we need to pad with additional zero bytes.
    // These zero bytes should not appear in the data chunk length header
    // but probably do get included for the length bytes in the file header
    if (length % 2 != 0) yield 0x00;
  }

  @override
  int get length => totalSamples * format.blockAlign;

  int get totalSamples {
    int sum = note.msDuration * format.sampleRate ~/ 1000;
    return sum;
  }

  @override
  String get sGroupId => _sGroupId;

  @override
  int get bytesPadding => length % 2 == 0 ? 0 : 1;
}
