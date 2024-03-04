library wave_generator;

import 'wavegeneratorfiles/chunk.dart';
import 'wavegeneratorfiles/data_chunk8.dart';
import 'wavegeneratorfiles/data_chunk16.dart';
import 'wavegeneratorfiles/data_chunk32.dart';
import 'wavegeneratorfiles/data_chunk32float.dart';
import 'wavegeneratorfiles/format_chunk.dart';
import 'wavegeneratorfiles/wave_header.dart';

/// Bit-depth per sample.
enum BitDepth {
  depth8Bit,
  depth16Bit,
  depth32Bit,
  depth32Float,
}

/// Waveform for a tone.
enum Waveform {
  sine,
  square,
  triangle,
}

/// Represents a single tone.
class Note {
  /// Frequency in Hz.
  final double fNought;

  /// Frequency in Hz. Used if generating more than a single frequency
  final double fEnd;

  /// Duration in milliseconds.
  final int msDuration;

  /// Waveform of the tone.
  final Waveform waveform = Waveform.sine;

  /// Volume in the range 0.0 - 1.0.
  final double volume;

  /// checks if the note is a sweep
  final bool isSweep;

  /// number of steps between fNought and fEnd
  final int steps;

  /// main constructor
  Note(this.fNought, this.fEnd, this.msDuration, this.volume, this.isSweep,
      this.steps) {
    if (volume < 0.0 || volume > 1.0) {
      throw ArgumentError('Volume should be between 0.0 and 1.0');
    }
    if (fEnd < 0.0 || fEnd < 0.0 || steps < 0) {
      throw ArgumentError('Frequency cannot be less than zero');
    }
    if (msDuration < 0.0) {
      throw ArgumentError('Duration cannot be less than zero');
    }
  }

  Note.singleTone(double fNought, int duration, double volume)
      : this(fNought, 0, duration, volume, false, 0);

  factory Note.fullLinearSweep(int duration, double volume) {
    return Note(20, 20000, duration, volume, true, 0);
  }
}

/// Generates simple waveforms as uncompressed PCM audio data.
class WaveGenerator {
  /// Samples generated per second.
  final int sampleRate;

  /// Bit-depth of each audio sample.
  final BitDepth bitDepth;

  //
  factory WaveGenerator.simple() {
    return const WaveGenerator(44100, BitDepth.depth8Bit);
  }

  const WaveGenerator(this.sampleRate, this.bitDepth);

  /// Generate a byte stream equivalent to a wav file of the Note argument
  Stream<int> generate(Note note) async* {
    var formatHeader = FormatChunk(1, sampleRate, bitDepth);
    var dataChunk = _getDataChunk(formatHeader, note);
    var fileHeader = WaveHeader(formatHeader, dataChunk);

    await for (int data in fileHeader.bytes()) {
      yield data;
    }
    await for (int data in formatHeader.bytes()) {
      yield data;
    }
    await for (int data in dataChunk.bytes()) {
      yield data;
    }
  }

  DataChunk _getDataChunk(FormatChunk format, Note note) {
    switch (bitDepth) {
      case BitDepth.depth8Bit:
        return DataChunk8(format, note);
      case BitDepth.depth16Bit:
        return DataChunk16(format, note);
      case BitDepth.depth32Bit:
        return DataChunk32(format, note);
      case BitDepth.depth32Float:
        return DataChunk32Float(format, note);
      default:
        throw UnimplementedError();
    }
  }
}
