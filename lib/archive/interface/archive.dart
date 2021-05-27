import 'file.dart';

/// A collection of files
abstract class Archive {
  String? get comment;

  /// Add a file to the archive.
  void addFile(ArchiveFile file);

  /// Get a file from the archive.
  ArchiveFile operator [](int index);

  /// Find a file with the given [name] in the archive. If the file isn't found,
  /// null will be returned.
  ArchiveFile? findFile(String name);

  /// The number of files in the archive.
  int numberOfFiles();

  /// The name of the file at the given [index].
  String fileName(int index);

  /// The decompressed size of the file at the given [index].
  int fileSize(int index);

  /// The decompressed data of the file at the given [index].
  List<int> fileData(int index);

  ArchiveFile get first;

  ArchiveFile get last;

  bool get isEmpty;

  bool get isNotEmpty;

  Iterable<ArchiveFile> get iterable;
}
