import '../interface/archive.dart';
import '../interface/file.dart';

class ArchiveImpl implements Archive {
  /// The list of files in the archive.
  final List<ArchiveFile> _files = [];

  @override
  String? comment;

  @override
  void addFile(ArchiveFile file) => _files.add(file);

  @override
  ArchiveFile operator [](int index) => _files[index];

  @override
  ArchiveFile? findFile(String name) {
    for (final f in _files) {
      if (f.name == name) {
        return f;
      }
    }
    return null;
  }

  @override
  int numberOfFiles() => _files.length;

  @override
  String fileName(int index) => _files[index].name;

  @override
  int fileSize(int index) => _files[index].size;

  @override
  List<int> fileData(int index) => _files[index].content as List<int>;

  @override
  ArchiveFile get first => _files.first;

  @override
  ArchiveFile get last => _files.last;

  @override
  bool get isEmpty => _files.isEmpty;

  @override
  bool get isNotEmpty => _files.isNotEmpty;

  @override
  Iterable<ArchiveFile> get iterable => _files;
}
