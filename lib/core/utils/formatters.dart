import 'package:intl/intl.dart';

class Formatters {
  static String formatDate(DateTime date) =>
      DateFormat('dd/MM/yyyy').format(date);
  static String formatTime(DateTime time) => DateFormat('HH:mm').format(time);

  static String weekdayAbbr(DateTime date) {
    const abbr = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    return abbr[date.weekday % 7];
  }
}
