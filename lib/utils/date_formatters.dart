const monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String formatShortDate(DateTime date) =>
    '${monthNames[date.month - 1].substring(0, 3)} ${date.day}';

String formatDateRange(DateTime start, DateTime end) {
  if (start == end) {
    return '${monthNames[start.month - 1]} ${start.day}, ${start.year}';
  }
  if (start.year == end.year && start.month == end.month) {
    return '${monthNames[start.month - 1]} ${start.day}–${end.day}, ${start.year}';
  }
  return '${formatShortDate(start)}, ${start.year} – ${formatShortDate(end)}, ${end.year}';
}

String formatCurrency(double value, {int decimals = 0}) {
  final whole = value.toStringAsFixed(decimals).split('.');
  final digits = whole.first;
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[index]);
  }
  return '\$${buffer.toString()}${whole.length > 1 ? '.${whole.last}' : ''}';
}
