/// Tolerant JSON readers: the backend omits empty fields (`omitempty`).
String? str(Object? v) => v is String && v.isNotEmpty ? v : null;
String strOr(Object? v, [String fallback = '']) => v is String ? v : fallback;
int intOr(Object? v, [int fallback = 0]) => v is num ? v.toInt() : fallback;
int? intN(Object? v) => v is num ? v.toInt() : null;
double? dblN(Object? v) => v is num ? v.toDouble() : null;
bool boolOr(Object? v, [bool fallback = false]) => v is bool ? v : fallback;
DateTime? date(Object? v) => v is String ? DateTime.tryParse(v) : null;
Map<String, dynamic> obj(Object? v) =>
    v is Map ? v.cast<String, dynamic>() : const {};
List<Map<String, dynamic>> objList(Object? v) => v is List
    ? v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
    : const [];
