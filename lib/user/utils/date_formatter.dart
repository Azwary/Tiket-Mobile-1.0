import 'package:intl/intl.dart';

String formatTanggalIndo(String tanggal) {
  return DateFormat('d MMMM yyyy', 'id').format(DateTime.parse(tanggal));
}
