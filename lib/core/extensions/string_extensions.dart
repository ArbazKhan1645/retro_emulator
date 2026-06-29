extension StringExtensions on String {
  /// Returns initials (max 2 chars) from a string
  String get initials {
    final words = trim().split(' ');
    if (words.isEmpty) return '';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  /// Capitalize first letter
  String get capitalized {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// True if this is a supported ROM extension
  bool get isRomExtension {
    const exts = ['.bin', '.md', '.gen', '.smd', '.32x'];
    return exts.contains(toLowerCase());
  }

  /// Get file extension (including dot)
  String get fileExtension {
    final idx = lastIndexOf('.');
    if (idx == -1) return '';
    return substring(idx).toLowerCase();
  }

  /// Get filename without extension
  String get fileNameWithoutExtension {
    final name = split('/').last.split('\\').last;
    final idx = name.lastIndexOf('.');
    if (idx == -1) return name;
    return name.substring(0, idx);
  }

  /// Format bytes to human readable
  String get bytesToReadable {
    final bytes = int.tryParse(this) ?? 0;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Truncate with ellipsis
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - 3)}...';
  }
}

extension IntExtensions on int {
  /// Format seconds to HH:MM:SS
  String get toPlayTime {
    final h = this ~/ 3600;
    final m = (this % 3600) ~/ 60;
    final s = this % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  /// Format bytes
  String get toReadableBytes {
    if (this < 1024) return '$this B';
    if (this < 1024 * 1024) return '${(this / 1024).toStringAsFixed(1)} KB';
    if (this < 1024 * 1024 * 1024) {
      return '${(this / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(this / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
