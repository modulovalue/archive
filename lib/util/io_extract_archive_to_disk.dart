import 'dart:io';

import '../archive/interface/archive.dart';
import '../base/impl/input_stream.dart';
import '../bzip2/impl/bzip2_decoder.dart';
import '../gzip/impl/gzip_decoder.dart';
import '../io/input_file_stream.dart';
import '../io/output_file_stream.dart';
import '../tar/tar_decoder.dart';
import '../zip/zip_decoder.dart';

void extractFileToDisk(String inputPath, String outputPath, {String? password}) {
  Directory? tempDir;
  var archivePath = inputPath;
  if (inputPath.endsWith('tar.gz') || inputPath.endsWith('tgz')) {
    tempDir = Directory.systemTemp.createTempSync('dart_archive');
    archivePath = '${tempDir.path}${Platform.pathSeparator}temp.tar';
    final input = InputFileStream(inputPath);
    final output = OutputFileStream(archivePath);
    const GZipDecoderImpl().decodeStream(input, output);
    input.close();
    output.close();
  } else if (inputPath.endsWith('tar.bz2') || inputPath.endsWith('tbz')) {
    tempDir = Directory.systemTemp.createTempSync('dart_archive');
    archivePath = '${tempDir.path}${Platform.pathSeparator}temp.tar';
    final input = InputFileStream(inputPath);
    final output = OutputFileStream(archivePath);
    BZip2DecoderImpl().decodeBuffer(input, output: output);
    input.close();
    output.close();
  }
  Archive archive;
  if (archivePath.endsWith('tar')) {
    final input = InputFileStream(archivePath);
    archive = TarDecoder().decodeBuffer(input);
  } else if (archivePath.endsWith('zip')) {
    final input = InputStreamImpl(File(archivePath).readAsBytesSync());
    archive = ZipDecoder().decodeBuffer(input, password: password);
  } else {
    throw ArgumentError.value(inputPath, 'inputPath', 'Must end tar.gz, tgz, tar.bz2, tbz, tar or zip.');
  }
  for (final file in archive.iterable) {
    if (file.isFile) {
      final f = File('${outputPath}${Platform.pathSeparator}${file.name}');
      f.parent.createSync(recursive: true);
      f.writeAsBytesSync(file.content as List<int>);
    }
  }
  if (tempDir != null) {
    tempDir.delete(recursive: true);
  }
}
