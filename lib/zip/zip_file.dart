import '../base/impl/crc32.dart';
import '../base/impl/exception.dart';
import '../base/impl/input_stream.dart';
import '../base/interface/input_stream.dart';
import '../zlib/inflate.dart';

class ZipFile {
  static const int STORE = 0;
  static const int DEFLATE = 8;
  static const int BZIP2 = 12;
  static const int SIGNATURE = 0x04034b50;

  int signature = SIGNATURE; // 4 bytes
  int version = 0; // 2 bytes
  int flags = 0; // 2 bytes
  int compressionMethod = 0; // 2 bytes
  int lastModFileTime = 0; // 2 bytes
  int lastModFileDate = 0; // 2 bytes
  int? crc32; // 4 bytes
  int? compressedSize; // 4 bytes
  int? uncompressedSize; // 4 bytes
  String filename = ''; // 2 bytes length, n-bytes data
  List<int> extraField = []; // 2 bytes length, n-bytes data
  ZipFileHeader? header;

  ZipFile([InputStreamImpl? input, this.header, String? password]) {
    if (input != null) {
      signature = input.readUint32();
      if (signature != SIGNATURE) {
        throw const ArchiveExceptionImpl('Invalid Zip Signature');
      } else {
        version = input.readUint16();
        flags = input.readUint16();
        compressionMethod = input.readUint16();
        lastModFileTime = input.readUint16();
        lastModFileDate = input.readUint16();
        crc32 = input.readUint32();
        compressedSize = input.readUint32();
        uncompressedSize = input.readUint32();
        final fn_len = input.readUint16();
        final ex_len = input.readUint16();
        filename = input.readString(size: fn_len);
        extraField = input.readBytes(ex_len).toUint8List();
        // Read compressedSize bytes for the compressed data.
        _rawContent = input.readBytes(header!.compressedSize!);
        if (password != null) {
          _initKeys(password);
          _isEncrypted = true;
        }
        // If bit 3 (0x08) of the flags field is set, then the CRC-32 and file
        // sizes are not known when the header is written. The fields in the
        // local header are filled with zero, and the CRC-32 and size are
        // appended in a 12-byte structure (optionally preceded by a 4-byte
        // signature) immediately after the compressed data:
        if (flags & 0x08 != 0) {
          final sigOrCrc = input.readUint32();
          if (sigOrCrc == 0x08074b50) {
            crc32 = input.readUint32();
          } else {
            crc32 = sigOrCrc;
          }
          compressedSize = input.readUint32();
          uncompressedSize = input.readUint32();
        }
      }
    }
  }

  /// This will decompress the data (if necessary) in order to calculate the
  /// crc32 checksum for the decompressed data and verify it with the value
  /// stored in the zip.
  bool verifyCrc32() {
    _computedCrc32 ??= const Crc32Impl().getCrc32(content);
    return _computedCrc32 == crc32;
  }

  /// Get the decompressed content from the file.  The file isn't decompressed
  /// until it is requested.
  List<int> get content {
    if (_content == null) {
      if (_isEncrypted) {
        _rawContent = _decodeRawContent(_rawContent);
        _isEncrypted = false;
      }
      if (compressionMethod == DEFLATE) {
        _content = Inflate.buffer(_rawContent, uncompressedSize).getBytes();
        compressionMethod = STORE;
      } else {
        _content = _rawContent.toUint8List();
      }
    }
    return _content!;
  }

  dynamic get rawContent {
    if (_content != null) {
      return _content;
    } else {
      return _rawContent;
    }
  }

  @override
  String toString() => filename;

  void _initKeys(String password) {
    _keys[0] = 305419896;
    _keys[1] = 591751049;
    _keys[2] = 878082192;
    password.codeUnits.forEach(_updateKeys);
  }

  void _updateKeys(int c) {
    _keys[0] = const Crc32Impl().CRC32(_keys[0], c);
    _keys[1] += _keys[0] & 0xff;
    _keys[1] = _keys[1] * 134775813 + 1;
    _keys[2] = const Crc32Impl().CRC32(_keys[2], _keys[1] >> 24);
  }

  int _decryptByte() {
    final temp = (_keys[2] & 0xffff) | 2;
    return ((temp * (temp ^ 1)) >> 8) & 0xff;
  }

  void _decodeByte(int c) => _updateKeys(c ^ _decryptByte());

  InputStreamImpl _decodeRawContent(InputStream input) {
    for (var i = 0; i < 12; ++i) {
      _decodeByte(_rawContent.readByte());
    }
    final bytes = _rawContent.toUint8List();
    for (var i = 0; i < bytes.length; ++i) {
      final temp = bytes[i] ^ _decryptByte();
      _updateKeys(temp);
      bytes[i] = temp;
    }
    return InputStreamImpl(bytes);
  }

  /// Content of the file. If compressionMethod is not STORE, then it is
  /// still compressed.
  late InputStream _rawContent;
  List<int>? _content;
  int? _computedCrc32;
  bool _isEncrypted = false;
  final _keys = <int>[0, 0, 0];
}

class ZipFileHeader {
  static const int SIGNATURE = 0x02014b50;
  int versionMadeBy = 0; // 2 bytes
  int versionNeededToExtract = 0; // 2 bytes
  int generalPurposeBitFlag = 0; // 2 bytes
  int compressionMethod = 0; // 2 bytes
  int lastModifiedFileTime = 0; // 2 bytes
  int lastModifiedFileDate = 0; // 2 bytes
  int? crc32; // 4 bytes
  int? compressedSize; // 4 bytes
  int? uncompressedSize; // 4 bytes
  int? diskNumberStart; // 2 bytes
  int? internalFileAttributes; // 2 bytes
  int? externalFileAttributes; // 4 bytes
  int? localHeaderOffset; // 4 bytes
  String filename = '';
  List<int> extraField = [];
  String fileComment = '';
  ZipFile? file;

  ZipFileHeader([InputStream? input, InputStreamImpl? bytes, String? password]) {
    if (input != null) {
      versionMadeBy = input.readUint16();
      versionNeededToExtract = input.readUint16();
      generalPurposeBitFlag = input.readUint16();
      compressionMethod = input.readUint16();
      lastModifiedFileTime = input.readUint16();
      lastModifiedFileDate = input.readUint16();
      crc32 = input.readUint32();
      compressedSize = input.readUint32();
      uncompressedSize = input.readUint32();
      final fname_len = input.readUint16();
      final extra_len = input.readUint16();
      final comment_len = input.readUint16();
      diskNumberStart = input.readUint16();
      internalFileAttributes = input.readUint16();
      externalFileAttributes = input.readUint32();
      localHeaderOffset = input.readUint32();
      if (fname_len > 0) {
        filename = input.readString(size: fname_len);
      }
      if (extra_len > 0) {
        final extra = input.readBytes(extra_len);
        extraField = extra.toUint8List();
        final id = extra.readUint16();
        final size = extra.readUint16();
        if (id == 1) {
          // Zip64 extended information
          // Original
          // Size       8 bytes    Original uncompressed file size
          // Compressed
          // Size       8 bytes    Size of compressed data
          // Relative Header
          // Offset     8 bytes    Offset of local header record
          // Disk Start
          // Number     4 bytes    Number of the disk on which
          // this file starts
          if (size >= 8) {
            uncompressedSize = extra.readUint64();
          }
          if (size >= 16) {
            compressedSize = extra.readUint64();
          }
          if (size >= 24) {
            localHeaderOffset = extra.readUint64();
          }
          if (size >= 28) {
            diskNumberStart = extra.readUint32();
          }
        }
      }
      if (comment_len > 0) {
        fileComment = input.readString(size: comment_len);
      }
      if (bytes != null) {
        bytes.offset = localHeaderOffset!;
        file = ZipFile(bytes, this, password);
      }
    }
  }

  @override
  String toString() => filename;
}

class ZipDirectory {
  // End of Central Directory Record
  static const int SIGNATURE = 0x06054b50;
  static const int ZIP64_EOCD_LOCATOR_SIGNATURE = 0x07064b50;
  static const int ZIP64_EOCD_LOCATOR_SIZE = 20;
  static const int ZIP64_EOCD_SIGNATURE = 0x06064b50;
  static const int ZIP64_EOCD_SIZE = 56;

  int filePosition = -1;
  int numberOfThisDisk = 0; // 2 bytes
  int diskWithTheStartOfTheCentralDirectory = 0; // 2 bytes
  int totalCentralDirectoryEntriesOnThisDisk = 0; // 2 bytes
  int totalCentralDirectoryEntries = 0; // 2 bytes
  late int centralDirectorySize; // 4 bytes
  late int centralDirectoryOffset; // 2 bytes
  String zipFileComment = ''; // 2 bytes, n bytes
  // Central Directory
  List<ZipFileHeader> fileHeaders = [];

  ZipDirectory();

  ZipDirectory.read(InputStreamImpl input, {String? password}) {
    filePosition = _findSignature(input);
    input.offset = filePosition;
    final signature = input.readUint32(); // ignore: unused_local_variable
    numberOfThisDisk = input.readUint16();
    diskWithTheStartOfTheCentralDirectory = input.readUint16();
    totalCentralDirectoryEntriesOnThisDisk = input.readUint16();
    totalCentralDirectoryEntries = input.readUint16();
    centralDirectorySize = input.readUint32();
    centralDirectoryOffset = input.readUint32();
    final len = input.readUint16();
    if (len > 0) {
      zipFileComment = input.readString(size: len);
    }
    _readZip64Data(input);
    final dirContent = input.subset(centralDirectoryOffset, centralDirectorySize);
    while (!dirContent.isEOS) {
      final fileSig = dirContent.readUint32();
      if (fileSig != ZipFileHeader.SIGNATURE) {
        break;
      }
      fileHeaders.add(ZipFileHeader(dirContent, input, password));
    }
  }

  void _readZip64Data(InputStreamImpl input) {
    final ip = input.offset;
    // Check for zip64 data.
    // Zip64 end of central directory locator
    // signature                       4 bytes  (0x07064b50)
    // number of the disk with the
    // start of the zip64 end of
    // central directory               4 bytes
    // relative offset of the zip64
    // end of central directory record 8 bytes
    // total number of disks           4 bytes
    final locPos = filePosition - ZIP64_EOCD_LOCATOR_SIZE;
    if (locPos < 0) {
      return;
    } else {
      final zip64 = input.subset(locPos, ZIP64_EOCD_LOCATOR_SIZE);
      var sig = zip64.readUint32();
      // If this ins't the signature we're looking for, nothing more to do.
      if (sig != ZIP64_EOCD_LOCATOR_SIGNATURE) {
        input.offset = ip;
      } else {
        final startZip64Disk = zip64.readUint32(); // ignore: unused_local_variable
        final zip64DirOffset = zip64.readUint64();
        final numZip64Disks = zip64.readUint32(); // ignore: unused_local_variable
        input.offset = zip64DirOffset;
        // Zip64 end of central directory record
        // signature                       4 bytes  (0x06064b50)
        // size of zip64 end of central
        // directory record                8 bytes
        // version made by                 2 bytes
        // version needed to extract       2 bytes
        // number of this disk             4 bytes
        // number of the disk with the
        // start of the central directory  4 bytes
        // total number of entries in the
        // central directory on this disk  8 bytes
        // total number of entries in the
        // central directory               8 bytes
        // size of the central directory   8 bytes
        // offset of start of central
        // directory with respect to
        // the starting disk number        8 bytes
        // zip64 extensible data sector    (variable size)
        sig = input.readUint32();
        if (sig != ZIP64_EOCD_SIGNATURE) {
          input.offset = ip;
          return;
        } else {
          final zip64EOCDSize = input.readUint64(); // ignore: unused_local_variable
          final zip64Version = input.readUint16(); // ignore: unused_local_variable
          // ignore: unused_local_variable
          final zip64VersionNeeded = input.readUint16();
          final zip64DiskNumber = input.readUint32();
          final zip64StartDisk = input.readUint32();
          final zip64NumEntriesOnDisk = input.readUint64();
          final zip64NumEntries = input.readUint64();
          final dirSize = input.readUint64();
          final dirOffset = input.readUint64();
          numberOfThisDisk = zip64DiskNumber;
          diskWithTheStartOfTheCentralDirectory = zip64StartDisk;
          totalCentralDirectoryEntriesOnThisDisk = zip64NumEntriesOnDisk;
          totalCentralDirectoryEntries = zip64NumEntries;
          centralDirectorySize = dirSize;
          centralDirectoryOffset = dirOffset;
          input.offset = ip;
        }
      }
    }
  }

  int _findSignature(InputStreamImpl input) {
    final pos = input.offset;
    final length = input.length;
    // The directory and archive contents are written to the end of the zip
    // file.  We need to search from the end to find these structures,
    // starting with the 'End of central directory' record (EOCD).
    for (var ip = length - 4; ip >= 0; --ip) {
      input.offset = ip;
      final sig = input.readUint32();
      if (sig == SIGNATURE) {
        input.offset = pos;
        return ip;
      }
    }
    throw const ArchiveExceptionImpl('Could not find End of Central Directory Record');
  }
}
