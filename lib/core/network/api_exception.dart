/// Categories the UI reacts to differently (see docs/SCREEN_SPEC.md states).
enum ApiErrorKind {
  network,
  timeout,
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  validation,
  rateLimited,
  server,

  /// A write request hit an expired access token. The token has been
  /// refreshed but the request was not replayed (only GET is retried).
  sessionRefreshed,
  unknown,
}

class ApiException implements Exception {
  ApiException({
    required this.kind,
    required this.message,
    this.statusCode,
    this.requestId,
    this.fieldErrors = const {},
    this.retryAfter,
  });

  final ApiErrorKind kind;
  final String message;
  final int? statusCode;

  /// `X-Request-ID` of the failed call; shown on error screens (D-030).
  final String? requestId;

  /// 422 field errors, `field -> message`.
  final Map<String, String> fieldErrors;

  /// From the `Retry-After` header on 429.
  final Duration? retryAfter;

  static ApiErrorKind kindForStatus(int status) {
    switch (status) {
      case 400:
        return ApiErrorKind.badRequest;
      case 401:
        return ApiErrorKind.unauthorized;
      case 403:
        return ApiErrorKind.forbidden;
      case 404:
        return ApiErrorKind.notFound;
      case 409:
        return ApiErrorKind.conflict;
      case 422:
        return ApiErrorKind.validation;
      case 429:
        return ApiErrorKind.rateLimited;
    }
    if (status >= 500) return ApiErrorKind.server;
    return ApiErrorKind.unknown;
  }

  /// Parses `errors` from the error envelope. The backend sends a map
  /// (`field -> message`); an array of `{field, message}` is accepted too.
  static Map<String, String> parseFieldErrors(Object? raw) {
    final out = <String, String>{};
    if (raw is Map) {
      raw.forEach((k, v) => out['$k'] = '$v');
    } else if (raw is List) {
      for (final item in raw) {
        if (item is Map && item['field'] != null) {
          out['${item['field']}'] = '${item['message'] ?? ''}';
        }
      }
    }
    return out;
  }

  static Duration? parseRetryAfter(String? header) {
    if (header == null) return null;
    final secs = int.tryParse(header.trim());
    if (secs != null) return Duration(seconds: secs < 0 ? 0 : secs);
    return null;
  }

  @override
  String toString() =>
      'ApiException($kind, $statusCode, requestId: $requestId)'; // no bodies
}
