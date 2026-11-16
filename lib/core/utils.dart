import 'package:intl/intl.dart';

String fmtIDR(num n) {
  if (n >= 1000000000) {
    return 'Rp ${(n / 1000000000).toStringAsFixed(3).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '')} M';
  }
  if (n >= 1000000) {
    return 'Rp ${(n / 1000000).toStringAsFixed(0)} Jt';
  }
  final formatter = NumberFormat.decimalPattern('id');
  return 'Rp ${formatter.format(n)}';
}
