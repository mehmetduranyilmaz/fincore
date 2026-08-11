abstract final class CategoryStrings {
  static const String title = 'Kategoriler';
  static const String create = 'Kategori Oluştur';
  static const String edit = 'Kategoriyi Düzenle';
  static const String name = 'Ad';
  static const String icon = 'Simge';
  static const String color = 'Renk';
  static const String type = 'Tür';
  static const String income = 'Gelir';
  static const String expense = 'Gider';
  static const String category = 'Kategori';
  static const String noCategory = 'Kategori yok';
  static const String save = 'Kaydet';
  static const String delete = 'Sil';
  static const String cancel = 'İptal';
  static const String retry = 'Tekrar Dene';
  static const String requiredField = 'Bu alan zorunludur.';
  static const String noCategories = 'Henüz kategori yok';
  static const String noCategoriesDescription =
      'İşlemlerinizi düzenlemek için bir kategori oluşturun.';
  static const String unableToLoad = 'Kategoriler yüklenemedi.';
  static const String deleteTitle = 'Kategori silinsin mi?';
  static const String deleteMessage =
      'Bu kategori artık yeni işlemlerde kullanılamayacak.';
  static const String categoryNotFound = 'Kategori bulunamadı.';

  static String iconName(String icon) {
    return switch (icon) {
      'shopping_cart' => 'Alışveriş',
      'directions_car' => 'Ulaşım',
      'subscriptions' => 'Abonelikler',
      'movie' => 'Eğlence',
      'bolt' => 'Faturalar',
      'restaurant' => 'Yeme İçme',
      'home' => 'Ev',
      'payments' => 'Ödemeler',
      'trending_up' => 'Yatırım',
      _ => 'Kategori',
    };
  }

  static String displayName(String name) {
    return switch (name) {
      'Groceries' => 'Market',
      'Transportation' => 'Ulaşım',
      'Subscriptions' => 'Abonelikler',
      'Entertainment' => 'Eğlence',
      'Utilities' => 'Faturalar',
      'Food' => 'Yeme İçme',
      'Rent' => 'Kira',
      'Salary' => 'Maaş',
      'Investment Income' => 'Yatırım Geliri',
      _ => name,
    };
  }

  static String nameFromId(String categoryId) {
    return switch (categoryId) {
      'category-grocery' => 'Market',
      'category-market' => 'Market',
      'category-transport' => 'Ulaşım',
      'category-subscription' => 'Abonelikler',
      'category-entertainment' => 'Eğlence',
      'category-utilities' => 'Faturalar',
      'category-food' => 'Yeme İçme',
      'category-rent' => 'Kira',
      'category-salary' => 'Maaş',
      'category-investment' => 'Yatırım Geliri',
      _ => categoryId,
    };
  }
}
