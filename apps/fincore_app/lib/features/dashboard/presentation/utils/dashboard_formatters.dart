abstract final class DashboardFormatters {
  static String currency(double value) {
    return '₺${value.toStringAsFixed(2)}';
  }

  static String date(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');

    return '$day.$month.${value.year}';
  }
}
