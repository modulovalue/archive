import '../../base/impl/input_stream.dart';
import '../../zlib/inflate.dart';
import '../interface/file.dart';

/// A file contained in an Archive.
class ArchiveFileImpl implements ArchiveFile {
  static const int STORE = 0;
  static const int DEFLATE = 8;

  @override
  String name;
  @override
  int size = 0;
  @override
  int mode = 420; // octal 644 (-rw-r--r--)
  @override
  int ownerId = 0;
  @override
  int groupId = 0;
  @override
  int lastModTime = 0;
  @override
  bool isFile = true;
  @override
  bool isSymbolicLink = false;
  @override
  String nameOfLinkedFile = '';
  int? _compressionType;
  InputStreamImpl? _rawContent;
  dynamic _content;
  @override
  int? crc32;
  @override
  String? comment;
  @override
  bool compress = true;

  ArchiveFileImpl(this.name, this.size, dynamic content, [this._compressionType = STORE]) {
    name = name.replaceAll('\\', '/');
    if (content is List<int>) {
      _content = content;
      _rawContent = InputStreamImpl(_content);
    } else if (content is InputStreamImpl) {
      _rawContent = InputStreamImpl.from(content);
    }
  }

  @override
  int get unixPermissions => mode & 0x1FF;

  ArchiveFileImpl.noCompress(this.name, this.size, dynamic content) {
    name = name.replaceAll('\\', '/');
    compress = false;
    if (content is List<int>) {
      _content = content;
      _rawContent = InputStreamImpl(_content);
    } else if (content is InputStreamImpl) {
      _rawContent = InputStreamImpl.from(content);
    }
  }

  ArchiveFileImpl.stream(this.name, this.size, dynamic content_stream) {
    // Paths can only have / path separators
    name = name.replaceAll('\\', '/');
    compress = true;
    _content = content_stream;
    //_rawContent = content_stream;
    _compressionType = STORE;
  }

  @override
  dynamic get content {
    if (_content == null) {
      decompress();
    }
    return _content;
  }

  @override
  void decompress() {
    if (_content == null && _rawContent != null) {
      if (_compressionType == DEFLATE) {
        _content = Inflate.buffer(_rawContent!, size).getBytes();
      } else {
        _content = _rawContent!.toUint8List();
      }
      _compressionType = STORE;
    }
  }

  @override
  bool get isCompressed => _compressionType != STORE;

  @override
  int? get compressionType => _compressionType;

  @override
  InputStreamImpl? get rawContent => _rawContent;

  @override
  String toString() => name;
}
