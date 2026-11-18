const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

String _two(int n) => n.toString().padLeft(2, '0');

/// 2026-11-18T03:27:00Z → "18 Nov 2026, 10:27" in the device time zone.
/// Hand-written to avoid an `intl` dependency for one format.
String formatDateTime(DateTime value) {
  final d = value.toLocal();
  return '${d.day} ${_months[d.month - 1]} ${d.year}, ${_two(d.hour)}:${_two(d.minute)}';
}
