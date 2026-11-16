import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'api_response.dart';

typedef Clock = DateTime Function();

/// Central REST client for the Leventa backend.
///
/// - Parses the `{success, message, data, meta}` envelope and `X-Request-ID`.
/// - Attaches the bearer token and refreshes it with a single in-flight
///   refresh; only GET requests are replayed after a refresh.
/// - Retries a GET at most once (network error / timeout / 5xx), never a 429.
/// - Never logs tokens, passwords or bodies.
class ApiClient {
  ApiClient({
    required String baseUrl,
    required this.tokens,
    Dio? dio,
    Clock? clock,
    this.retryDelay = const Duration(milliseconds: 800),
  }) : _dio = dio ?? Dio(),
       _clock = clock ?? DateTime.now {
    _dio.options
      ..baseUrl = baseUrl
      ..connectTimeout = const Duration(seconds: 15)
      ..receiveTimeout = const Duration(seconds: 30)
      ..sendTimeout = const Duration(seconds: 60)
      ..validateStatus = ((_) => true)
      ..headers['Accept'] = 'application/json';
  }

  final TokenStorage tokens;
  final Dio _dio;
  final Clock _clock;
  final Duration retryDelay;

  /// Called after the refresh token was rejected and the session cleared.
  Future<void> Function()? onSessionExpired;

  /// Called after a successful token rotation.
  void Function()? onTokensRefreshed;

  TokenPair? _pair;
  bool _loaded = false;
  Completer<String?>? _refreshing;

  static const _refreshMargin = Duration(seconds: 30);

  Future<void> _load() async {
    if (_loaded) return;
    _pair = await tokens.read();
    _loaded = true;
  }

  Future<bool> hasSession() async {
    await _load();
    return _pair != null;
  }

  Future<void> setSession(TokenPair pair) async {
    _pair = pair;
    _loaded = true;
    await tokens.write(pair);
  }

  Future<void> clearSession() async {
    _pair = null;
    _loaded = true;
    await tokens.clear();
  }

  // ---- public verbs -------------------------------------------------------

  Future<ApiResponse> get(
    String path, {
    Map<String, dynamic>? query,
    bool auth = true,
  }) async => _parse(await _send('GET', path, query: query, auth: auth));

  Future<ApiResponse> post(
    String path, {
    Object? body,
    bool auth = true,
  }) async => _parse(await _send('POST', path, data: body, auth: auth));

  Future<ApiResponse> put(String path, {Object? body}) async =>
      _parse(await _send('PUT', path, data: body));

  Future<ApiResponse> patch(String path, {Object? body}) async =>
      _parse(await _send('PATCH', path, data: body));

  Future<ApiResponse> delete(String path) async =>
      _parse(await _send('DELETE', path));

  /// Multipart upload. Not replayed after a token refresh.
  Future<ApiResponse> upload(String path, FormData form) async =>
      _parse(await _send('POST', path, data: form));

  /// Authenticated binary download (ownership documents).
  Future<Uint8List> download(String path) async {
    final res = await _send('GET', path, responseType: ResponseType.bytes);
    final status = res.statusCode ?? 0;
    if (status >= 200 && status < 300) {
      final data = res.data;
      if (data is Uint8List) return data;
      if (data is List<int>) return Uint8List.fromList(data);
      return Uint8List(0);
    }
    Object? body;
    try {
      body = jsonDecode(utf8.decode((res.data as List).cast<int>()));
    } catch (_) {}
    throw _errorFrom(res, body);
  }

  // ---- internals ----------------------------------------------------------

  Future<Response<dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? data,
    bool auth = true,
    ResponseType? responseType,
  }) async {
    final token = auth ? await _accessToken() : null;
    var res = await _requestWithRetry(
      method,
      path,
      query,
      data,
      token,
      responseType,
    );
    if (res.statusCode == 401 && token != null) {
      final fresh = await _refresh();
      if (fresh == null) throw _sessionExpiredError(res);
      if (method != 'GET') {
        throw ApiException(
          kind: ApiErrorKind.sessionRefreshed,
          statusCode: 401,
          message: 'Sesi diperbarui. Silakan ulangi aksi.',
          requestId: _requestId(res),
        );
      }
      res = await _requestWithRetry(
        method,
        path,
        query,
        data,
        fresh,
        responseType,
      );
      if (res.statusCode == 401) {
        await _expire();
        throw _sessionExpiredError(res);
      }
    }
    return res;
  }

  ApiException _sessionExpiredError(Response<dynamic> res) => ApiException(
    kind: ApiErrorKind.unauthorized,
    statusCode: 401,
    message: 'Sesi berakhir. Silakan masuk kembali.',
    requestId: _requestId(res),
  );

  Future<String?> _accessToken() async {
    await _load();
    final pair = _pair;
    if (pair == null) return null;
    if (pair.expiresAt.isAfter(_clock().add(_refreshMargin))) {
      return pair.accessToken;
    }
    final fresh = await _refresh();
    if (fresh == null) {
      throw ApiException(
        kind: ApiErrorKind.unauthorized,
        statusCode: 401,
        message: 'Sesi berakhir. Silakan masuk kembali.',
      );
    }
    return fresh;
  }

  Future<Response<dynamic>> _requestWithRetry(
    String method,
    String path,
    Map<String, dynamic>? query,
    Object? data,
    String? token,
    ResponseType? responseType,
  ) async {
    final canRetry = method == 'GET';
    for (var attempt = 0; ; attempt++) {
      try {
        final res = await _dio.request<dynamic>(
          path,
          data: data,
          queryParameters: query,
          options: Options(
            method: method,
            responseType: responseType,
            headers: {if (token != null) 'Authorization': 'Bearer $token'},
          ),
        );
        final status = res.statusCode ?? 0;
        if (canRetry && attempt == 0 && status >= 500) {
          await Future<void>.delayed(retryDelay);
          continue;
        }
        return res;
      } on DioException catch (e) {
        if (canRetry && attempt == 0 && _isTransient(e)) {
          await Future<void>.delayed(retryDelay);
          continue;
        }
        throw _mapDio(e);
      }
    }
  }

  bool _isTransient(DioException e) =>
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.unknown;

  ApiException _mapDio(DioException e) {
    final timeout =
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout;
    return ApiException(
      kind: timeout ? ApiErrorKind.timeout : ApiErrorKind.network,
      message: timeout
          ? 'Koneksi terlalu lama. Periksa jaringan Anda.'
          : 'Tidak dapat terhubung ke server. Periksa koneksi internet.',
    );
  }

  /// Single in-flight refresh. Returns the new access token, or null when the
  /// refresh token was rejected (session cleared, [onSessionExpired] called).
  /// Network errors and 429 are rethrown without clearing the session.
  Future<String?> _refresh() {
    final inflight = _refreshing;
    if (inflight != null) return inflight.future;
    final completer = Completer<String?>();
    _refreshing = completer;
    () async {
      try {
        final refreshToken = _pair?.refreshToken;
        if (refreshToken == null) {
          completer.complete(null);
          return;
        }
        final Response<dynamic> res;
        try {
          res = await _dio.post<dynamic>(
            '/auth/refresh',
            data: {'refresh_token': refreshToken},
          );
        } on DioException catch (e) {
          completer.completeError(_mapDio(e));
          return;
        }
        final status = res.statusCode ?? 0;
        if (status == 200) {
          final body = (res.data as Map).cast<String, dynamic>();
          final pair = TokenPair.fromAuthJson(
            (body['data'] as Map).cast<String, dynamic>(),
            _clock(),
          );
          await setSession(pair);
          completer.complete(pair.accessToken);
          onTokensRefreshed?.call();
        } else if (status == 429 || status >= 500) {
          completer.completeError(_errorFrom(res, res.data));
        } else {
          await _expire();
          completer.complete(null);
        }
      } catch (e) {
        if (!completer.isCompleted) completer.completeError(e);
      } finally {
        _refreshing = null;
      }
    }();
    return completer.future;
  }

  Future<void> _expire() async {
    await clearSession();
    await onSessionExpired?.call();
  }

  String? _requestId(Response<dynamic> res) =>
      res.headers.value('x-request-id');

  ApiResponse _parse(Response<dynamic> res) {
    final status = res.statusCode ?? 0;
    var body = res.data;
    if (body is String && body.isNotEmpty) {
      try {
        body = jsonDecode(body);
      } catch (_) {}
    }
    if (status < 200 || status >= 300) throw _errorFrom(res, body);
    if (body is Map) {
      final meta = body['meta'];
      return ApiResponse(
        data: body['data'],
        message: body['message'] as String?,
        meta: meta is Map ? PageMeta.fromJson(meta.cast()) : null,
        requestId: _requestId(res),
        statusCode: status,
      );
    }
    return ApiResponse(
      data: body,
      requestId: _requestId(res),
      statusCode: status,
    );
  }

  ApiException _errorFrom(Response<dynamic> res, Object? body) {
    final status = res.statusCode ?? 0;
    final kind = ApiException.kindForStatus(status);
    final map = body is Map ? body : const {};
    final serverMessage = map['message'];
    return ApiException(
      kind: kind,
      statusCode: status,
      message: serverMessage is String && serverMessage.isNotEmpty
          ? serverMessage
          : defaultMessage(kind),
      fieldErrors: ApiException.parseFieldErrors(map['errors']),
      retryAfter: kind == ApiErrorKind.rateLimited
          ? ApiException.parseRetryAfter(res.headers.value('retry-after'))
          : null,
      requestId: _requestId(res),
    );
  }

  static String defaultMessage(ApiErrorKind kind) {
    switch (kind) {
      case ApiErrorKind.badRequest:
        return 'Permintaan tidak valid.';
      case ApiErrorKind.unauthorized:
        return 'Sesi berakhir. Silakan masuk kembali.';
      case ApiErrorKind.forbidden:
        return 'Anda tidak memiliki akses.';
      case ApiErrorKind.notFound:
        return 'Data tidak ditemukan atau tidak tersedia untuk Anda.';
      case ApiErrorKind.conflict:
        return 'Terjadi konflik data.';
      case ApiErrorKind.validation:
        return 'Periksa kembali isian Anda.';
      case ApiErrorKind.rateLimited:
        return 'Terlalu banyak permintaan. Tunggu sebentar.';
      case ApiErrorKind.server:
        return 'Server sedang bermasalah. Coba lagi nanti.';
      default:
        return 'Terjadi kesalahan.';
    }
  }
}
