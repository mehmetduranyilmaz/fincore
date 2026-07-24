typedef RefreshAccessToken = Future<String> Function();
typedef RefreshFailureHandler = Future<void> Function();

final class RefreshTokenCoordinator {
  RefreshTokenCoordinator(
    this._refreshAccessToken, {
    RefreshFailureHandler? onRefreshFailure,
  }) : _onRefreshFailure = onRefreshFailure ?? _ignoreRefreshFailure;

  final RefreshAccessToken _refreshAccessToken;
  final RefreshFailureHandler _onRefreshFailure;

  Future<String>? _activeRefresh;

  Future<String> refresh() {
    return _activeRefresh ??= _runRefresh();
  }

  Future<String> _runRefresh() async {
    try {
      return await _refreshAccessToken();
    } on Object catch (error, stackTrace) {
      await _onRefreshFailure();
      Error.throwWithStackTrace(error, stackTrace);
    } finally {
      _activeRefresh = null;
    }
  }

  static Future<void> _ignoreRefreshFailure() async {}
}
