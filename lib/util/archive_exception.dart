/// An exception thrown when there was a problem in the archive library.
class ArchiveException extends FormatException {
  const ArchiveException(String message, [dynamic source, int? offset]) : super(message, source, offset);
}
