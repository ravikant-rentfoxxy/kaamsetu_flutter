/// Transport-agnostic API surface. Two implementations:
///  - [HttpApiClient]: the real Express backend (`/api/v1`).
///  - [MockBackend]: in-memory demo backend with sample data.
abstract class ApiClient {
  Future<dynamic> get(String path, {Map<String, dynamic>? query});
  Future<dynamic> post(String path, [dynamic body]);
  Future<dynamic> put(String path, [dynamic body]);

  /// URL of the offer-letter PDF, or null when it should be rendered in-app.
  String? offerLetterUrl(String hireId);
}

class ApiException implements Exception {
  final int status;
  final String message;
  const ApiException(this.status, this.message);

  @override
  String toString() => message;
}
