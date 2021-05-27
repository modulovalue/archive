import '../archive/impl/archive.dart';
import '../archive/impl/file.dart';
import '../archive/interface/archive.dart';
import '../base/impl/crc32.dart';
import '../base/impl/exception.dart';
import '../base/impl/input_stream.dart';
import 'zip_file.dart';

/// Decode a zip formatted buffer into an [Archive] object.
class ZipDecoder {
  late ZipDirectory directory;

  Archive decodeBytes(
    List<int> data, {
    bool verify = false,
    String? password,
  }) =>
      decodeBuffer(InputStreamImpl(data), verify: verify, password: password);

  Archive decodeBuffer(
    InputStreamImpl input, {
    bool verify = false,
    String? password,
  }) {
    directory = ZipDirectory.read(input, password: password);
    final archive = ArchiveImpl();
    for (final zfh in directory.fileHeaders) {
      final zf = zfh.file!;
      // The attributes are stored in base 8
      final mode = zfh.externalFileAttributes!;
      final compress = zf.compressionMethod != ZipFile.STORE;
      if (verify) {
        final computedCrc = const Crc32Impl().getCrc32(zf.content);
        if (computedCrc != zf.crc32) {
          throw const ArchiveExceptionImpl('Invalid CRC for file in archive.');
        }
      }
      final dynamic content = zf.rawContent;
      final file = ArchiveFileImpl(zf.filename, zf.uncompressedSize!, content, zf.compressionMethod);
      file.mode = mode >> 16;
      // see https://github.com/brendan-duncan/archive/issues/21
      // UNIX systems has a creator version of 3 decimal at 1 byte offset
      if (zfh.versionMadeBy >> 8 == 3) {
        //final bool isDirectory = file.mode & 0x7000 == 0x4000;
        final isFile = file.mode & 0x3F000 == 0x8000;
        file.isFile = isFile;
      } else {
        file.isFile = !file.name.endsWith('/');
      }
      file.crc32 = zf.crc32;
      file.compress = compress;
      file.lastModTime = zf.lastModFileDate << 16 | zf.lastModFileTime;
      archive.addFile(file);
    }
    return archive;
  }
}
