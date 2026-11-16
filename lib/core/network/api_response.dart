class PageMeta {
  const PageMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasNext => page < totalPages;

  factory PageMeta.fromJson(Map<String, dynamic> j) => PageMeta(
    page: (j['page'] as num?)?.toInt() ?? 1,
    limit: (j['limit'] as num?)?.toInt() ?? 20,
    total: (j['total'] as num?)?.toInt() ?? 0,
    totalPages: (j['total_pages'] as num?)?.toInt() ?? 0,
  );
}

/// Parsed success envelope `{success, message, data, meta}`.
class ApiResponse {
  const ApiResponse({
    required this.data,
    this.message,
    this.meta,
    this.requestId,
    this.statusCode,
  });

  final Object? data;
  final String? message;
  final PageMeta? meta;
  final String? requestId;
  final int? statusCode;

  Map<String, dynamic> get dataMap =>
      (data as Map?)?.cast<String, dynamic>() ?? const {};

  List<Map<String, dynamic>> get dataList => ((data as List?) ?? const [])
      .whereType<Map>()
      .map((e) => e.cast<String, dynamic>())
      .toList();
}

class Paged<T> {
  const Paged(this.items, this.meta);
  final List<T> items;
  final PageMeta meta;
}
