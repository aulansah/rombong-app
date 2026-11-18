/// Formats an integer amount of rupiah: 85000 → "Rp85.000".
///
/// The backend sends money as an integer (no floats), so formatting is plain
/// digit grouping; no `intl` dependency is needed.
String formatRupiah(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '${amount < 0 ? '-' : ''}Rp$buffer';
}
