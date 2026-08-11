import 'package:fincore_app/features/accounts/domain/entities/account_type.dart';

abstract final class AccountStrings {
  static const String title = 'Hesaplar';
  static const String archived = 'Arşivlendi';
  static const String noAccounts = 'Henüz hesap yok';
  static const String noAccountsDescription = 'Hesaplarınız burada görünecek.';
  static const String unableToLoad = 'Hesaplar yüklenemedi.';
  static const String retry = 'Tekrar Dene';
  static const String checking = 'Vadesiz Hesap';
  static const String savings = 'Birikim Hesabı';
  static const String cash = 'Nakit';
  static const String investment = 'Yatırım Hesabı';
  static const String currentBalance = 'Güncel Bakiye';
  static const String totalIncome = 'Toplam Gelir';
  static const String totalExpense = 'Toplam Gider';
  static const String balanceUnavailable = 'Bakiye bilgisi kullanılamıyor';
  static const String create = 'Hesap Ekle';
  static const String edit = 'Hesabı Düzenle';
  static const String delete = 'Hesabı Sil';
  static const String deleteTitle = 'Hesap silinsin mi?';
  static const String deleteMessage =
      'Hesap listeden kaldırılacak, geçmiş hareketleri korunacaktır.';
  static const String cancel = 'Vazgeç';
  static const String save = 'Kaydet';
  static const String name = 'Hesap Adı';
  static const String type = 'Hesap Türü';
  static const String currency = 'Para Birimi';
  static const String openingBalance = 'Başlangıç Bakiyesi';
  static const String bank = 'Banka';
  static const String selectBank = 'Bir banka seçin';
  static const String iban = 'IBAN (İsteğe Bağlı)';
  static const String ibanHint = 'TR00 0000 0000 0000 0000 0000 00';
  static const String invalidIban = 'Geçerli bir Türkiye IBAN’ı girin.';
  static const String required = 'Bu alan zorunludur.';
  static const String invalidAmount = 'Geçerli bir bakiye girin.';

  static String accountType(AccountType type) {
    return switch (type) {
      AccountType.checking => checking,
      AccountType.savings => savings,
      AccountType.cash => cash,
      AccountType.investment => investment,
    };
  }

  static String displayName(String name) {
    return switch (name) {
      'Primary Account' => 'Ana Hesap',
      'Secondary Account' => 'İkinci Hesap',
      'Savings' => 'Birikim Hesabı',
      'USD Account' => 'Dolar Hesabı',
      'Office Cash' => 'Ofis Kasası',
      _ => name,
    };
  }

  static String nameFromId(String accountId) {
    return switch (accountId) {
      'account-1' => 'Ana Hesap',
      'account-2' => 'Birikim Hesabı',
      'account-4' => 'Dolar Hesabı',
      'account-5' => 'Ofis Kasası',
      _ => accountId,
    };
  }
}
