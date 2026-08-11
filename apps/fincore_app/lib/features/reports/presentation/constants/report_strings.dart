abstract final class ReportStrings {
  static const title = 'Harcama Raporları';
  static const subtitle = 'Harcama türlerine göre dağılım';
  static const monthly = 'Aylık';
  static const yearly = 'Yıllık';
  static const previousPeriod = 'Önceki dönem';
  static const nextPeriod = 'Sonraki dönem';
  static const currentPeriod = 'Bu dönem';
  static const totalExpense = 'Toplam Harcama';
  static const transactionCount = 'İşlem Sayısı';
  static const averageExpense = 'Ortalama Harcama';
  static const categoryCount = 'Harcama Türü';
  static const noExpenses = 'Bu dönemde harcama yok';
  static const noExpensesDescription =
      'Seçilen dönemdeki giderler kategori bazında burada gösterilecek.';
  static const unableToLoad = 'Harcama raporu yüklenemedi.';
  static const retry = 'Tekrar Dene';
  static const unknownCurrency = 'Para birimi belirlenemeyen hareketler';
  static const transaction = 'işlem';
  static const details = 'Hareketleri göster';

  static const _months = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  static String monthYear(DateTime date) =>
      '${_months[date.month - 1]} ${date.year}';
}
