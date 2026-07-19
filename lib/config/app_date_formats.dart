/// Centralized date/time format patterns used across the app.
class AppDateFormats {
  AppDateFormats._();

  static const String sqlDateTimeMinute = 'yyyy-MM-dd HH:mm';
  static const String sqlDateTimeSecond = 'yyyy-MM-dd HH:mm:ss';
  static const String mediumDate = 'dd MMM yyyy';
  static const String shortDate = 'dd MMM';
  static const String numericShortDate = 'dd/MM/yyyy';
  static const String time12Hour = 'hh:mm a';
  static const String isoDate = 'yyyy-MM-dd';
  static const String mediumDateTime = 'dd MMM • HH:mm';
  static const String fullDateTime = 'dd/MM/yyyy hh:mm a';
  static const String fileNameDateTime = 'yyyyMMdd-HHmmss';
}
