import 'dart:convert';
import 'dart:typed_data';

class ByteHelpers {
  static Uint8List toBytes(String str) {
    var encoder = const AsciiEncoder();
    return encoder.convert(str);
  }
}
