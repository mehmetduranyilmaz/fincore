abstract final class BudgetStrings {
  static const String title = 'Bütçeler';
  static const String create = 'Bütçe Oluştur';
  static const String edit = 'Bütçe Düzenle';
  static const String monthlyBudget = 'Aylık Bütçe';
  static const String spent = 'Harcanan';
  static const String remaining = 'Kalan';
  static const String category = 'Kategori';
  static const String period = 'Dönem';
  static const String month = 'Ay';
  static const String year = 'Yıl';
  static const String thisMonth = 'Bu Ay';
  static const String save = 'Kaydet';
  static const String cancel = 'İptal';
  static const String delete = 'Sil';
  static const String retry = 'Tekrar Dene';
  static const String noBudgets = 'Henüz bütçe yok';
  static const String noBudgetsDescription =
      'Aylık harcamalarınızı takip etmek için bir bütçe oluşturun.';
  static const String unableToLoad = 'Bütçeler yüklenemedi.';
  static const String budgetNotFound = 'Bütçe bulunamadı.';
  static const String requiredField = 'Bu alan zorunludur.';
  static const String invalidAmount = 'Sıfırdan büyük geçerli bir tutar girin.';
  static const String selectCategory = 'Bir gider kategorisi seçin';
  static const String noExpenseCategories = 'Gider kategorisi bulunamadı.';
  static const String deleteTitle = 'Bütçe silinsin mi?';
  static const String deleteMessage =
      'Bu bütçe kalıcı olarak listeden kaldırılacak.';
  static const String deletedCategory = 'Silinmiş kategori';

  static const List<String> months = [
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

  static String periodLabel(int month, int year) {
    return '${months[month - 1]} $year';
  }
}
