// ignore: deprecated_member_use, shortcut: GetX/plugins still use flutter/material types; migrate to material_ui when they do.
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../network/api_exception.dart';
import '../network/api_response.dart';
import '../utils/throttle.dart';
import 'state_views.dart';

/// Loads one value; `force` = pull-to-refresh / retry (bypasses cache).
class AsyncLoader<T> extends StatefulWidget {
  const AsyncLoader({super.key, required this.load, required this.builder});

  final Future<T> Function(bool force) load;
  final Widget Function(
    BuildContext context,
    T value,
    Future<void> Function() reload,
  )
  builder;

  @override
  State<AsyncLoader<T>> createState() => AsyncLoaderState<T>();
}

class AsyncLoaderState<T> extends State<AsyncLoader<T>> {
  final _latest = LatestOnly();
  T? _value;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _run(false);
  }

  Future<void> reload() => _run(true);

  Future<void> _run(bool force) async {
    final token = _latest.next();
    setState(() {
      _loading = _value == null;
      _error = null;
    });
    try {
      final v = await widget.load(force);
      if (!mounted || !_latest.isLatest(token)) return;
      setState(() {
        _value = v;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || !_latest.isLatest(token)) return;
      setState(() {
        _error = e;
        _loading = false;
        // 401/403/404: never keep showing data the user may no longer see.
        if (e is ApiException &&
            (e.kind == ApiErrorKind.forbidden ||
                e.kind == ApiErrorKind.notFound ||
                e.kind == ApiErrorKind.unauthorized)) {
          _value = null;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = _value;
    if (v != null && _error == null) return widget.builder(context, v, reload);
    if (_loading) return const LoadingView();
    if (v != null) {
      // Refresh failed but data is still allowed: show it with the error.
      return Column(
        children: [
          MaterialBanner(
            content: Text(
              _error is ApiException
                  ? errorText(_error as ApiException)
                  : 'Gagal memuat ulang.',
            ),
            actions: [
              TextButton(onPressed: reload, child: const Text('Coba lagi')),
            ],
          ),
          Expanded(child: widget.builder(context, v, reload)),
        ],
      );
    }
    return ErrorView(error: _error!, onRetry: reload);
  }
}

/// Server-paginated list with pull-to-refresh and infinite scroll.
/// Change [queryKey] to restart from page 1 (new search/filter).
class PagedList<T> extends StatefulWidget {
  const PagedList({
    super.key,
    required this.fetch,
    required this.itemBuilder,
    required this.empty,
    this.queryKey,
    this.header,
    this.minItemWidth,
    this.padding = const EdgeInsets.fromLTRB(Gap.m, Gap.s, Gap.m, Gap.l),
    this.maxOffset = 10000,
  });

  final Future<Paged<T>> Function(int page, bool force) fetch;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Widget empty;
  final Object? queryKey;
  final Widget? header;

  /// When set, items flow into columns of at least this width (tablet).
  final double? minItemWidth;
  final EdgeInsets padding;
  final int maxOffset;

  @override
  State<PagedList<T>> createState() => PagedListState<T>();
}

class PagedListState<T> extends State<PagedList<T>> {
  final _latest = LatestOnly();
  final _items = <T>[];
  PageMeta? _meta;
  Object? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load(1, false);
  }

  @override
  void didUpdateWidget(PagedList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.queryKey != widget.queryKey) _load(1, false);
  }

  Future<void> refresh() => _load(1, true);

  bool get _hasMore {
    final m = _meta;
    if (m == null || !m.hasNext) return false;
    return m.page * m.limit <= widget.maxOffset;
  }

  bool get _hitOffsetCap {
    final m = _meta;
    return m != null && m.hasNext && m.page * m.limit > widget.maxOffset;
  }

  Future<void> _load(int page, bool force) async {
    final token = _latest.next();
    setState(() {
      _loading = true;
      _error = null;
      if (page == 1 && force == false) {
        _items.clear();
        _meta = null;
      }
    });
    try {
      final res = await widget.fetch(page, force);
      if (!mounted || !_latest.isLatest(token)) return;
      setState(() {
        if (page == 1) _items.clear();
        _items.addAll(res.items);
        _meta = res.meta;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || !_latest.isLatest(token)) return;
      setState(() {
        _error = e;
        _loading = false;
        if (e is ApiException &&
            (e.kind == ApiErrorKind.forbidden ||
                e.kind == ApiErrorKind.unauthorized)) {
          _items.clear(); // never show a 403 as cached data
        }
      });
    }
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.extentAfter < 400 &&
        !_loading &&
        _error == null &&
        _hasMore) {
      _load(_meta!.page + 1, false);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final header = widget.header;
    Widget body;
    if (_items.isEmpty && _loading) {
      body = const SliverFillRemaining(
        hasScrollBody: false,
        child: LoadingView(),
      );
    } else if (_items.isEmpty && _error != null) {
      body = SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorView(error: _error!, onRetry: refresh),
      );
    } else if (_items.isEmpty) {
      body = SliverFillRemaining(hasScrollBody: false, child: widget.empty);
    } else {
      body = SliverPadding(
        padding: widget.padding,
        sliver: SliverLayoutBuilder(
          builder: (context, constraints) {
            final min = widget.minItemWidth;
            final cols = min == null
                ? 1
                : (constraints.crossAxisExtent / min).floor().clamp(1, 4);
            final rows = (_items.length / cols).ceil();
            return SliverList.separated(
              itemCount: rows + 1,
              separatorBuilder: (_, _) => const SizedBox(height: Gap.m),
              itemBuilder: (context, r) {
                if (r == rows) return _footer(context);
                if (cols == 1) return widget.itemBuilder(context, _items[r]);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < cols; i++) ...[
                      if (i > 0) const SizedBox(width: Gap.m),
                      Expanded(
                        child: r * cols + i < _items.length
                            ? widget.itemBuilder(context, _items[r * cols + i])
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                );
              },
            );
          },
        ),
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: RefreshIndicator(
        onRefresh: refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            ?(header == null ? null : SliverToBoxAdapter(child: header)),
            body,
          ],
        ),
      ),
    );
  }

  Widget _footer(BuildContext context) {
    if (_loading) return const LoadingView(label: 'Memuat halaman berikutnya');
    if (_error != null) {
      final e = _error;
      return Center(
        child: Column(
          children: [
            Text(
              e is ApiException ? errorText(e) : 'Gagal memuat.',
              textAlign: TextAlign.center,
              style: context.t.bodySmall,
            ),
            TextButton(
              onPressed: () => _load((_meta?.page ?? 0) + 1, false),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }
    if (_hitOffsetCap) {
      return Text(
        'Hasil terlalu banyak. Persempit pencarian atau filter untuk melihat lebih lanjut.',
        textAlign: TextAlign.center,
        style: context.t.bodySmall,
      );
    }
    final total = _meta?.total;
    return Text(
      total == null ? '' : '$total hasil',
      textAlign: TextAlign.center,
      style: context.t.bodySmall,
    );
  }
}
