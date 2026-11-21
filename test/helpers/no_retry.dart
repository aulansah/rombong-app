/// Riverpod 3 retries failing providers automatically. Tests turn that off
/// (as the app does in main.dart) so an error reaches the provider's state
/// and `.future` immediately.
Duration? noRetry(int retryCount, Object error) => null;
