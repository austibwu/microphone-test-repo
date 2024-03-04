import 'dart:typed_data';

import 'byte_helpers.dart';
import 'chunk.dart';

import '../wave_generator.dart';

class FormatChunk implements Chunk {
  final int bitsPerByte = 8;

  final String _sGroupId = 'fmt ';
  final int _dwChunkSize = 16;
  late int _wFormatTag;
  final int _wChannels;
  final int _dwSamplesPerSecond;
  late int _dwAverageBytesPerSecond;
  late int _wBlockAlign;
  late int _wBitsPerSample;

  FormatChunk(
    this._wChannels,
    this._dwSamplesPerSecond,
    BitDepth bitsPerSample,
  ) {
    switch (bitsPerSample) {
      case BitDepth.depth8Bit:
        _wBitsPerSample = 8;
        break;
      case BitDepth.depth16Bit:
        _wBitsPerSample = 16;
        break;
      case (BitDepth.depth32Bit || BitDepth.depth32Float):
        _wBitsPerSample = 32;
        break;
    }

    _wFormatTag = (bitsPerSample == BitDepth.depth32Float) ? 3 : 1;

    _wBlockAlign = _wChannels * (_wBitsPerSample ~/ bitsPerByte);
    _dwAverageBytesPerSecond = _wBlockAlign * _dwSamplesPerSecond;
  }

  @override
  int get length => _dwChunkSize;

  int get sampleRate => _dwSamplesPerSecond;

  int get blockAlign => _wBlockAlign;

  int get bytesPerSecond => _dwAverageBytesPerSecond;

  int get bitDepth => _wBitsPerSample;

  int get formatTag => _wFormatTag;

  @override
  String get sGroupId => _sGroupId;

  @override
  Stream<int> bytes() async* {
    // sGroupId
    var groupIdBytes = ByteHelpers.toBytes(_sGroupId);
    var bytes = groupIdBytes.buffer.asByteData();

    for (int i = 0; i < 4; i++) {
      yield bytes.getUint8(i);
    }

    // chunkLength
    var byteData = ByteData(4);
    byteData.setUint32(0, length, Endian.little);
    for (int i = 0; i < 4; i++) {
      yield byteData.getUint8(i);
    }

    // Audio format // 8,16,32 int => 1. 32float => 3
    byteData = ByteData(2);
    byteData.setUint16(0, _wFormatTag, Endian.little);
    for (int i = 0; i < 2; i++) {
      yield byteData.getUint8(i);
    }

    // Num channels
    byteData = ByteData(2);
    byteData.setUint16(0, _wChannels, Endian.little);
    for (int i = 0; i < 2; i++) {
      yield byteData.getUint8(i);
    }

    // Sample rate
    byteData = ByteData(4);
    byteData.setUint32(0, _dwSamplesPerSecond, Endian.little);
    for (int i = 0; i < 4; i++) {
      yield byteData.getUint8(i);
    }

    // Byte rate
    byteData = ByteData(4);
    byteData.setUint32(0, _dwAverageBytesPerSecond, Endian.little);
    for (int i = 0; i < 4; i++) {
      yield byteData.getUint8(i);
    }

    // Block align
    byteData = ByteData(2);
    byteData.setUint16(0, _wBlockAlign, Endian.little);
    for (int i = 0; i < 2; i++) {
      yield byteData.getUint8(i);
    }

    // Bits per sample
    byteData = ByteData(2);
    byteData.setUint16(0, _wBitsPerSample, Endian.little);
    for (int i = 0; i < 2; i++) {
      yield byteData.getUint8(i);
    }
  }
}
