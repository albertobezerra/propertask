import 'package:intl/intl.dart';

class Formatters {
  static String formatDate(DateTime date) =>
      DateFormat('dd/MM/yyyy').format(date);
  static String formatTime(DateTime time) => DateFormat('HH:mm').format(time);
}
