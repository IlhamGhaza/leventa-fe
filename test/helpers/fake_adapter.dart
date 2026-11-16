import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

class FakeReply {
  FakeReply(this.status, [this.body, this.headers = const {}]);
  final int status;
  final Object? body;
  final Map<String, String> headers;
}

class FakeCall {
  FakeCall(this.method, this.path, this.query, this.headers, this.body);
  final String method;
  final String path;
  final Map<String, dynamic> query;
  final Map<String, dynamic> headers;
  final Object? body;
  String? get auth => headers['Authorization'] as String?;
}

/// Dio adapter driven by a handler; records every call.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);
  FakeReply Function(FakeCall call) handler;
  final calls = <FakeCall>[];
  Object? throwOnce;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final call = FakeCall(
      options.method,
      options.path,
      options.queryParameters,
      options.headers,
      options.data,
    );
    calls.add(call);
    final t = throwOnce;
    if (t != null) {
      throwOnce = null;
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        error: t,
      );
    }
    final r = handler(call);
    final bytes = r.body is List<int>
        ? r.body as List<int>
        : utf8.encode(jsonEncode(r.body ?? {}));
    return ResponseBody.fromBytes(
      bytes,
      r.status,
      headers: {
        'content-type': ['application/json'],
        for (final e in r.headers.entries) e.key: [e.value],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> ok(Object? data, [Map<String, dynamic>? meta]) => {
  'success': true,
  'message': 'ok',
  'data': data,
  'meta': ?meta,
};

Map<String, dynamic> failBody(String message, [Object? errors]) => {
  'success': false,
  'message': message,
  'errors': ?errors,
};
