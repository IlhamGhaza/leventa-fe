import 'dart:io';

import 'package:get/get.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/deals/deal_repository.dart';
import '../features/documents/document_repository.dart';
import '../features/master_data/master_data_repository.dart';
import '../features/properties/data/property_repository.dart';
import 'cache/cache_store.dart';
import 'cache/cached_fetcher.dart';
import 'config/env.dart';
import 'network/api_client.dart';
import 'storage/token_storage.dart';

/// Wires the single instances. No hidden service locator inside widgets:
/// screens receive controllers via `Get.find` only at the top level.
Future<void> setupDependencies({
  TokenStorage? tokenStorage,
  PublicDiskCache? diskCache,
  ApiClient? apiClient,
  Future<Directory> Function()? documentsDir,
}) async {
  final api =
      apiClient ??
      ApiClient(
        baseUrl: Env.apiBaseUrl,
        tokens: tokenStorage ?? SecureTokenStorage(),
      );
  final cache = CacheStore();
  final documents = DocumentRepository(api, baseDir: documentsDir);

  late final AuthController auth;
  final fetcher = CachedFetcher(cache, () => auth.sessionKey);

  auth = AuthController(
    repository: AuthRepository(api),
    cache: cache,
    purgePrivateFiles: documents.purgeAll,
  );
  api.onSessionExpired = auth.onSessionExpired;
  api.onTokensRefreshed = () => auth.refreshMe();

  Get.put<ApiClient>(api, permanent: true);
  Get.put<CacheStore>(cache, permanent: true);
  Get.put<AuthController>(auth, permanent: true);
  Get.put<DocumentRepository>(documents, permanent: true);
  Get.put<PropertyRepository>(
    PropertyRepository(api, cache, fetcher),
    permanent: true,
  );
  Get.put<MasterDataRepository>(
    MasterDataRepository(api, cache, diskCache ?? PrefsPublicDiskCache()),
    permanent: true,
  );
  Get.put<DealRepository>(DealRepository(api, cache, fetcher), permanent: true);
}
