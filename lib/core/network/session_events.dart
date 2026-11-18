import 'dart:async';

/// Lets the network layer tell the rest of the app that the session ended
/// (refresh token rejected), without the network layer knowing about Blocs.
class SessionEvents {
  final _expired = StreamController<void>.broadcast();

  Stream<void> get expired => _expired.stream;

  void notifyExpired() {
    if (!_expired.isClosed) _expired.add(null);
  }

  Future<void> dispose() => _expired.close();
}
