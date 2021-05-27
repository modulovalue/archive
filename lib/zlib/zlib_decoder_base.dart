import 'dart:typed_data';

import '../base/interface/input_stream.dart';

/// Decompress data with the zlib format decoder.
abstract class ZLibDecoderBase {
  Uint8List decodeBytes(List<int> data, {bool verify = false});

  Uint8List decodeBuffer(InputStream input, {bool verify = false});
}
