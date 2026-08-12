/// Holds the current JWT in memory so the API client can attach it to every
/// request without hitting secure storage each time. Populated at app start by
/// [AuthProvider.restoreSession] and cleared on logout.
class TokenStore {
  String? current;
}
