import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Formatting helpers shared across the app. Prices use Indian grouping
/// (e.g. ₹1,25,000) which matches the marketplace audience.
abstract final class Formatters {
  static bool _dateSymbolsInitialized = false;

  /// Loads the `en_IN` date/number symbols used by the formatters below.
  /// Idempotent; call once from `main()` before rendering so that
  /// [DateFormat] with a non-default locale does not throw
  /// `LocaleDataException`.
  static Future<void> ensureDateSymbols() async {
    if (_dateSymbolsInitialized) return;
    _dateSymbolsInitialized = true;
    await initializeDateFormatting('en_IN');
  }

  static final NumberFormat _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  /// Formats a rupee amount with Indian digit grouping.
  static String inr(num value) => _inr.format(value);

  /// Short readable date, e.g. "12 Aug".
  static String dateLabel(DateTime date) =>
      DateFormat('d MMM', 'en_IN').format(date);

  /// Full readable date, e.g. "15 Aug 2026".
  static String fullDateLabel(DateTime date) =>
      DateFormat('d MMM yyyy', 'en_IN').format(date);

  /// Parses a backend `preferredDate` string (`YYYY-MM-DD`) into a readable
  /// label; returns the raw string if it cannot be parsed.
  static String dateLabelFromIso(String value) {
    final date = DateTime.tryParse(value);
    return date == null ? value : DateFormat('d MMM yyyy', 'en_IN').format(date);
  }

  /// Compact relative time for the notifications inbox, e.g. "Just now",
  /// "12m ago", "3h ago", "Yesterday", "12 Aug".
  static String timeAgoLabel(DateTime time, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final difference = reference.difference(time);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 2) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    if (time.year == reference.year) {
      return DateFormat('d MMM', 'en_IN').format(time);
    }
    return DateFormat('d MMM yyyy', 'en_IN').format(time);
  }

  /// Formats a 24h `HH:MM` backend `preferredTime` string as `10:30 AM`.
  static String timeLabelFromString(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return value;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return value;
    return timeOfDayLabel(TimeOfDay(hour: hour, minute: minute));
  }

  /// Formats a [TimeOfDay] as `10:30 AM`.
  static String timeOfDayLabel(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour == 0 ? 12 : hour}:$minute $period';
  }

  /// Compact "ends in" duration, e.g. "12h 5m".
  static String remainingDuration(int seconds) {
    if (seconds <= 0) return '';
    final duration = Duration(seconds: seconds);
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}
