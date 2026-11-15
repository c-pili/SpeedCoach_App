import 'dart:convert' show base64Encode, utf8;
import 'dart:typed_data';

class ByteBuffer {
  final List<int> _bytes = [];

  ByteBuffer();

  ByteBuffer.fromList(List<int> bytes) {
    _bytes.addAll(bytes);
  }

  void add(int byte) {
    _bytes.add(byte & 0xFF);
  }

  void addAll(Iterable<int> bytes) {
    _bytes.addAll(bytes.map((b) => b & 0xFF));
  }

  void addUint16(int value, {bool littleEndian = true}) {
    if (littleEndian) {
      _bytes.add(value & 0xFF);
      _bytes.add((value >> 8) & 0xFF);
    } else {
      _bytes.add((value >> 8) & 0xFF);
      _bytes.add(value & 0xFF);
    }
  }

  void addUint32(int value, {bool littleEndian = true}) {
    if (littleEndian) {
      _bytes.add(value & 0xFF);
      _bytes.add((value >> 8) & 0xFF);
      _bytes.add((value >> 16) & 0xFF);
      _bytes.add((value >> 24) & 0xFF);
    } else {
      _bytes.add((value >> 24) & 0xFF);
      _bytes.add((value >> 16) & 0xFF);
      _bytes.add((value >> 8) & 0xFF);
      _bytes.add(value & 0xFF);
    }
  }

  void addString(String str, {String encoding = 'utf-8'}) {
    if (encoding == 'utf-8') {
      _bytes.addAll(str.codeUnits);
    }
  }

  Uint8List toUint8List() => Uint8List.fromList(_bytes);
  List<int> toList() => List.unmodifiable(_bytes);
  int get length => _bytes.length;
  bool get isEmpty => _bytes.isEmpty;
  void clear() => _bytes.clear();
}

extension Uint8ListExtensions on Uint8List {
  String toBase64() => base64Encode(this);
  String toUtf8String() => utf8.decode(this);
}

extension ListIntExtensions on List<int> {
  Uint8List toUint8List() => Uint8List.fromList(this);
  String toBase64() => base64Encode(Uint8List.fromList(this));
  String toUtf8String() => utf8.decode(Uint8List.fromList(this));
}