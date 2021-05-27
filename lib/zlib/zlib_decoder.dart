import 'dart:typed_data';

import '../base/interface/input_stream.dart';
import 'zlib_decoder_stub.dart' //
    if (dart.library.io) '_zlib_decoder_io.dart'
    if (dart.library.js) '_zlib_decoder_js.dart';

/// Decompress data with the zlib format decoder.
class ZLibDecoder {
  static const int DEFLATE = 8;

  const ZLibDecoder();

  Uint8List decodeBytes(
    List<int> data, {
    bool verify = false,
  }) =>
      platformZLibDecoder.decodeBytes(data, verify: verify);

  Uint8List decodeBuffer(
    InputStream input, {
    bool verify = false,
  }) =>
      platformZLibDecoder.decodeBuffer(input, verify: verify);
}
