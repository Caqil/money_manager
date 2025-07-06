import '../utils/date_utils.dart';

extension DateTimeExtension on DateTime {
  // Format extensions
  String get shortDate => AppDateUtils.formatShortDate(this);
  String get longDate => AppDateUtils.formatLongDate(this);
  String get dayMonth => AppDateUtils.formatDayMonth(this);
  String get monthYear => AppDateUtils.formatMonthYear(this);
  String get timeOnly => AppDateUtils.formatTime(this);
  String get dateTime => AppDateUtils.formatDateTime(this);
  String get relativeDate => AppDateUtils.formatRelativeDate(this);

  // Date comparisons
  bool isSameDay(DateTime other) => AppDateUtils.isSameDay(this, other);
  bool isSameMonth(DateTime other) => AppDateUtils.isSameMonth(this, other);
  bool isSameYear(DateTime other) => AppDateUtils.isSameYear(this, other);

  // Date checks
  bool get isToday => AppDateUtils.isToday(this);
  bool get isYesterday => AppDateUtils.isYesterday(this);
  bool get isFuture => isAfter(DateTime.now());
  bool get isPast => isBefore(DateTime.now());

  // Date manipulations
  DateTime get startOfDay => AppDateUtils.startOfDay(this);
  DateTime get endOfDay => AppDateUtils.endOfDay(this);
  DateTime get startOfWeek => AppDateUtils.startOfWeek(this);
  DateTime get startOfMonth => AppDateUtils.startOfMonth(this);
  DateTime get endOfMonth => AppDateUtils.endOfMonth(this);

  // Add/subtract periods
  DateTime addDays(int days) => add(Duration(days: days));
  DateTime subtractDays(int days) => subtract(Duration(days: days));
  DateTime addWeeks(int weeks) => add(Duration(days: weeks * 7));
  DateTime subtractWeeks(int weeks) => subtract(Duration(days: weeks * 7));
  DateTime addMonths(int months) => DateTime(year, month + months, day);
  DateTime subtractMonths(int months) => DateTime(year, month - months, day);
  DateTime addYears(int years) => DateTime(year + years, month, day);
  DateTime subtractYears(int years) => DateTime(year - years, month, day);

  // Get age in different units
  int get ageInDays => DateTime.now().difference(this).inDays;
  int get ageInWeeks => (ageInDays / 7).floor();
  int get ageInMonths => DateTime.now().month - month + (DateTime.now().year - year) * 12;
  int get ageInYears => DateTime.now().year - year;

  // Week utilities
  int get weekOfYear => AppDateUtils.getWeekOfYear(this);
  int get daysInMonth => AppDateUtils.getDaysInMonth(year, month);

  // First/Last day helpers
  DateTime get firstDayOfMonth => DateTime(year, month, 1);
  DateTime get lastDayOfMonth => DateTime(year, month + 1, 0);
  DateTime get firstDayOfWeek => subtract(Duration(days: weekday - 1));
  DateTime get lastDayOfWeek => add(Duration(days: 7 - weekday));

  // Quarter utilities
  int get quarter => ((month - 1) / 3).floor() + 1;
  DateTime get firstDayOfQuarter {
    final quarterStartMonth = (quarter - 1) * 3 + 1;
    return DateTime(year, quarterStartMonth, 1);
  }
  DateTime get lastDayOfQuarter {
    final quarterEndMonth = quarter * 3;
    return DateTime(year, quarterEndMonth + 1, 0);
  }

  // Timezone utilities
  DateTime get toLocalTime => toLocal();
  DateTime get toUtcTime => toUtc();

  // Business day utilities
  bool get isWeekday => weekday <= 5;
  bool get isWeekend => weekday > 5;

  // Date range helpers
  bool isInRange(DateTime start, DateTime end) {
    return (isAfter(start) || isAtSameMomentAs(start)) &&
           (isBefore(end) || isAtSameMomentAs(end));
  }

  bool isInDateRange(DateTime start, DateTime end) {
    final thisDate = startOfDay;
    final startDate = start.startOfDay;
    final endDate = end.endOfDay;
    return thisDate.isInRange(startDate, endDate);
  }

  // Copy with time
  DateTime copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
    int? microsecond,
  }) {
    return DateTime(
      year ?? this.year,
      month ?? this.month,
      day ?? this.day,
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? this.second,
      millisecond ?? this.millisecond,
      microsecond ?? this.microsecond,
    );
  }
}
