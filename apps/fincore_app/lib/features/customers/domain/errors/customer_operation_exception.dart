final class CustomerOperationException implements Exception {
  const CustomerOperationException(this.message);

  final String message;

  @override
  String toString() => message;
}
