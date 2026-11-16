import 'package:intl/intl.dart';

/// Display-only formatting. Never used to compute money values.
class Fmt {
  const Fmt._();

  static final _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );
  static final _compact = NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 1,
  );
  static final _num = NumberFormat.decimalPattern('id_ID');

  static String rupiah(num? v) => v == null ? '-' : _rupiah.format(v);
  static String rupiahCompact(num? v) => v == null ? '-' : _compact.format(v);
  static String number(num? v) => v == null ? '-' : _num.format(v);
  static String area(num? v) => v == null ? '-' : '${_num.format(v)} m²';
  static String percent(num v) => '${_num.format(v)}%';

  static String distance(int? meters) {
    if (meters == null) return '-';
    if (meters < 1000) return '$meters m';
    return '${NumberFormat('#,##0.#', 'id_ID').format(meters / 1000)} km';
  }

  static String date(DateTime? d) =>
      d == null ? '-' : DateFormat('d MMM yyyy', 'id_ID').format(d.toLocal());

  static String dateTime(DateTime? d) => d == null
      ? '-'
      : DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(d.toLocal());

  static String isoDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
}
