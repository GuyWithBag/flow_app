String formatDuration(int totalSeconds) {
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  final s = totalSeconds % 60;

  if (h > 0) {
    return '${h}h ${m}m ${s}s';
  }
  return '${m}m ${s}s';
}
