import '../../base/interface/input_stream.dart';

/// A file contained in an Archive.
abstract class ArchiveFile {
  abstract String name;

  /// The uncompressed size of the file
  abstract int size;
  abstract int mode;
  abstract int ownerId;
  abstract int groupId;
  abstract int lastModTime;
  abstract bool isFile;
  abstract bool isSymbolicLink;
  abstract String nameOfLinkedFile;

  /// The crc32 checksum of the uncompressed content.
  abstract int? crc32;
  abstract String? comment;

  /// If false, this file will not be compressed when encoded to an archive
  /// format such as zip.
  abstract bool compress;

  int get unixPermissions;

  /// Get the content of the file, decompressing on demand as necessary.
  dynamic get content;

  /// If the file data is compressed, decompress it.
  void decompress();

  /// Is the data stored by this file currently compressed?
  bool get isCompressed;

  /// What type of compression is the raw data stored in
  int? get compressionType;

  /// Get the content without decompressing it first.
  InputStream? get rawContent;
}
