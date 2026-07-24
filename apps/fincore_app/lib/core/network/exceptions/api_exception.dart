base class ApiException implements Exception {
  const ApiException({required this.message, this.statusCode, this.data});

  final String message;
  final int? statusCode;
  final Object? data;

  @override
  String toString() {
    final code = statusCode;
    return code == null
        ? 'ApiException: $message'
        : 'ApiException($code): $message';
  }
}
