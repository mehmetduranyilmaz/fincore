enum Environment {
  dev(baseUrl: ''),
  test(baseUrl: ''),
  prod(baseUrl: '');

  const Environment({required this.baseUrl});

  final String baseUrl;
}
