// Tiny date/time formatters so we don't need the intl package.

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _monthsLong = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String monthShort(DateTime d) => _months[d.month - 1];
String monthLong(DateTime d) => _monthsLong[d.month - 1];
String weekdayShort(DateTime d) => _days[d.weekday - 1];

String timeOfDay(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
}

/// "Fri, Jun 28"
String shortDate(DateTime d) => '${weekdayShort(d)}, ${monthShort(d)} ${d.day}';

/// "Fri, Jun 28 · 6:00 PM"
String dateTime(DateTime d) => '${shortDate(d)} · ${timeOfDay(d)}';

/// "FRI 28 · 6:00 PM"
String tileDate(DateTime d) =>
    '${weekdayShort(d).toUpperCase()} ${d.day} · ${timeOfDay(d)}';

/// "Fri, Jun 28 · 6:00 PM – 9:00 PM"
String timeRange(DateTime a, DateTime b) {
  final sameDay = a.year == b.year && a.month == b.month && a.day == b.day;
  return sameDay
      ? '${shortDate(a)} · ${timeOfDay(a)} – ${timeOfDay(b)}'
      : '${dateTime(a)} – ${dateTime(b)}';
}

String relative(DateTime t, DateTime now) {
  final diff = now.difference(t);
  if (diff.isNegative) {
    final ahead = t.difference(now);
    if (ahead.inMinutes < 60) return 'in ${ahead.inMinutes}m';
    if (ahead.inHours < 24) return 'in ${ahead.inHours}h';
    return 'in ${ahead.inDays}d';
  }
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return shortDate(t);
}

String greeting(DateTime now) {
  if (now.hour < 12) return 'Good morning';
  if (now.hour < 18) return 'Good afternoon';
  return 'Good evening';
}
