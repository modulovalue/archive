import 'dart:io';
import 'dart:typed_data';

class ZLibEncoder {
  static const int DEFLATE = 8;

  const ZLibEncoder();

  Uint8List encode(
    List<int> data, {
    int? level,
  }) =>
      ZLibCodec(level: level ?? ZLibOption.defaultLevel).encoder.convert(data) as Uint8List;
}
