/// Build-time environment. Override with
/// `--dart-define=API_BASE_URL=https://api.example.com/api/v1`.
class Env {
  const Env._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api/v1',
  );

  /// Scheme + host + port of the backend, used to resolve `/uploads/...`.
  static String get origin {
    final uri = Uri.parse(apiBaseUrl);
    return uri.replace(path: '', query: null, fragment: null).toString();
  }

  /// Turns a backend file URL (often relative, e.g. `/uploads/x.jpg`) into an
  /// absolute URL. Returns null for empty input; never invents a URL.
  static String? resolveFileUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final base = origin.endsWith('/')
        ? origin.substring(0, origin.length - 1)
        : origin;
    return url.startsWith('/') ? '$base$url' : '$base/$url';
  }
}
