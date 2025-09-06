bool requiresVip(String quality) {
  final q = quality.trim().toUpperCase();
  if (q == 'AUTO' || q == 'OFFLINE') return false;
  if (q.contains('2K') || q.contains('4K')) return true;
  final match = RegExp(r"(\d{3,4})P").firstMatch(q);
  if (match != null) {
    final num = int.tryParse(match.group(1) ?? '0') ?? 0;
    return num >= 1080;
  }
  return false;
}

String formatDurationHMS(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
}
