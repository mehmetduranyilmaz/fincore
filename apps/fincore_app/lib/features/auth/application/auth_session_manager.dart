import 'dart:async';

import 'package:fincore_app/features/auth/domain/repositories/auth_repository.dart';

enum AuthSessionEvent { loggedOut }

final class AuthSessionManager {
  AuthSessionManager(this._authRepository);

  final AuthRepository _authRepository;
  final StreamController<AuthSessionEvent> _eventsController =
      StreamController<AuthSessionEvent>.broadcast(sync: true);

  Future<void>? _activeLogout;

  Stream<AuthSessionEvent> get events => _eventsController.stream;

  Future<void> logout() {
    return _activeLogout ??= _performLogout();
  }

  Future<void> _performLogout() async {
    try {
      await _logoutSafely();

      if (!_eventsController.isClosed) {
        _eventsController.add(AuthSessionEvent.loggedOut);
      }
    } finally {
      _activeLogout = null;
    }
  }

  Future<void> _logoutSafely() async {
    try {
      await _authRepository.logout();
    } on Object {
      return;
    }
  }

  void dispose() {
    unawaited(_eventsController.close());
  }
}
