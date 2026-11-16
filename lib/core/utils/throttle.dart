import 'dart:async';

import '../network/api_client.dart';

/// Debounces search input (~400 ms, docs/STATE_AND_ROUTING.md).
class Debouncer {
  Debouncer([this.delay = const Duration(milliseconds: 400)]);
  final Duration delay;
  Timer? _timer;

  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() => _timer?.cancel();
}

/// Tracks a 429 `Retry-After`. Retry stays disabled until it elapses;
/// nothing is retried automatically.
class RateLimitGate {
  RateLimitGate({Clock? clock}) : _clock = clock ?? DateTime.now;
  final Clock _clock;
  DateTime? _until;

  void block(Duration? retryAfter) {
    _until = _clock().add(retryAfter ?? const Duration(seconds: 60));
  }

  Duration get remaining {
    final u = _until;
    if (u == null) return Duration.zero;
    final d = u.difference(_clock());
    return d.isNegative ? Duration.zero : d;
  }

  bool get canRetry => remaining == Duration.zero;
}

/// Increments a token per request so a stale response (older query) is
/// ignored when a newer one was started.
class LatestOnly {
  int _token = 0;
  int next() => ++_token;
  bool isLatest(int token) => token == _token;
}
