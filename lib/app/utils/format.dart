// Shared display formatters (salary, dates, relative time). Used across worker
// and employer screens — keep one copy here, not per-screen.
import 'package:intl/intl.dart';

String formatSalary(num? n) {
  if (n == null) return '';
  if (n >= 1000) return '₹${(n / 1000).round()}k';
  return '₹$n';
}

/// Salary range label; "Negotiable" when no salary was set on the job.
String salaryRange(num? min, num? max, {bool en = true}) {
  if (min == null && max == null) return en ? 'Negotiable' : 'तय नहीं';
  if (min != null && max != null) return '${formatSalary(min)}–${formatSalary(max)}';
  return formatSalary(min ?? max);
}

final _inr = NumberFormat.decimalPattern('en_IN');
String formatInr(num? n) => '₹${_inr.format(n ?? 0)}';

String formatDate(DateTime? d) => d == null ? '' : DateFormat('dd MMM yyyy').format(d.toLocal());

String isoDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

String timeAgo(DateTime? d, String lang) {
  if (d == null) return '';
  final h = DateTime.now().difference(d).inHours;
  if (h < 1) return lang == 'en' ? 'just now' : 'अभी';
  if (h < 24) return lang == 'en' ? '${h}h ago' : '$h घंटे पहले';
  final days = h ~/ 24;
  return lang == 'en' ? '${days}d ago' : '$days दिन पहले';
}

String initials(String name, {String fallback = '?'}) {
  final parts = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2);
  final s = parts.map((w) => w[0].toUpperCase()).join();
  return s.isEmpty ? fallback : s;
}

DateTime? parseDate(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());
