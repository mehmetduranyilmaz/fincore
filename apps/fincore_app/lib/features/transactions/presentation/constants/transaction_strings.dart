import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';

abstract final class TransactionStrings {
  static const String title = 'İşlemler';
  static const String createManualExpense = 'Manuel Gider Oluştur';
  static const String createManualIncome = 'Manuel Gelir Oluştur';
  static const String createTransfer = 'Transfer Oluştur';
  static const String scanReceiptExpense = 'Kredi Kartı Fişi Tara';
  static const String scanWithCamera = 'Kamerayla Tara';
  static const String selectFromGallery = 'Galeriden Seç';
  static const String receiptReview = 'Fiş Bilgilerini Kontrol Et';
  static const String receiptReviewDescription =
      'Okunan alanları kontrol edin, gerekiyorsa düzeltin. Onayınız olmadan kayıt yapılmaz.';
  static const String scanAnotherReceipt = 'Başka Fiş Tara';
  static const String addCreditCard = 'Yeni Kredi Kartı Ekle';
  static const String cardMatchFound =
      'Fişteki son dört haneye göre kredi kartı eşleştirildi.';
  static const String cardMatchNotFound =
      'Fişteki kart bulunamadı. Yeni kart ekleyebilir veya listeden seçim yapabilirsiniz.';
  static const String installmentType = 'Ödeme Şekli';
  static const String paymentStatus = 'Ödeme Durumu';
  static const String cashPayment = 'Peşin';
  static const String openAccount = 'Açık Hesap';
  static const String openAccountCustomer = 'Müşteri';
  static const String selectOpenAccountCustomer = 'Açık hesap müşterisi seçin';
  static const String singlePayment = 'Tek Çekim';
  static const String installment = 'Taksit';
  static const String installmentCount = 'Taksit Sayısı';
  static const String installmentAmounts = 'Taksit Tutarları';
  static const String installmentTotalMismatch =
      'Taksitlerin toplamı harcama tutarına eşit olmalıdır.';
  static const String installmentCardRequired =
      'Taksitli işlem için kredi kartı seçmelisiniz.';
  static const String installmentSourceRequired =
      'Taksitli işlem için kredi kartı veya açık hesap müşterisi seçmelisiniz.';
  static const String expensePlanType = 'Gider Planı';
  static const String oneTimeExpense = 'Tek Seferlik';
  static const String recurringMonthlyExpense = 'Her Ay';
  static const String occurrenceCount = 'Kaç Ay Tekrarlansın?';
  static const String invalidOccurrenceCount = '2 ile 60 arasında ay girin.';
  static const String recurringExpenseHint =
      'Gelecek aylar ödeme takviminde planlanan gider olarak görünür; vadesinden önce gerçek bakiyeleri etkilemez.';
  static const String saveRecurringExpense = 'Gider Planını Kaydet';
  static const String manageRecurringExpenses = 'Tekrarlayan Giderler';
  static const String recurringExpensesDescription =
      'Aylık ödeme takvimine yansıyan planları buradan değiştirebilir veya silebilirsiniz.';
  static const String noRecurringExpenses = 'Tekrarlayan gider planı yok';
  static const String noRecurringExpensesDescription =
      'Her ay ödenecek aidat ve benzeri giderleri manuel gider ekranından ekleyebilirsiniz.';
  static const String editRecurringExpense = 'Gider Planını Düzenle';
  static const String deleteRecurringExpense = 'Gider planı silinsin mi?';
  static const String deleteRecurringExpenseDescription =
      'Plan, gelecek aylardaki ödeme takviminden kaldırılacaktır.';
  static const String recurringExpenseDeleted = 'Gider planı silindi.';
  static const String recurringExpenseUpdated = 'Gider planı güncellendi.';
  static const String convertToInstallments = 'Taksitlendir';
  static const String convertToInstallmentsTitle = 'İşlemi Taksitlendir';
  static const String installmentNumber = 'Taksit';
  static const String originalAmount = 'Toplam Harcama';
  static const String cancel = 'Vazgeç';
  static const String amount = 'Tutar';
  static const String description = 'Açıklama';
  static const String date = 'Tarih';
  static const String fromAccount = 'Gönderen Hesap';
  static const String toAccount = 'Alıcı Hesap';
  static const String selectAccount = 'Bir hesap seçin';
  static const String paymentSource = 'Hesap veya Kredi Kartı';
  static const String selectPaymentSource = 'Bir ödeme kaynağı seçin';
  static const String account = 'Hesap';
  static const String creditCard = 'Kredi Kartı';
  static const String saveExpense = 'Gideri Kaydet';
  static const String saveIncome = 'Geliri Kaydet';
  static const String saveTransfer = 'Transferi Kaydet';
  static const String requiredField = 'Bu alan zorunludur.';
  static const String invalidAmount = 'Geçerli bir tutar girin.';
  static const String noTransactions = 'Henüz işlem yok';
  static const String noTransactionsDescription =
      'İşlemleriniz burada görünecek.';
  static const String unableToLoad = 'İşlemler yüklenemedi.';
  static const String retry = 'Tekrar Dene';
  static const String search = 'İşlemlerde ara';
  static const String clearSearch = 'Aramayı temizle';
  static const String filterByDate = 'Tarih aralığı';
  static const String clearDateFilter = 'Tarih aralığını temizle';
  static const String clearAccountFilter = 'Tüm hesaplar';
  static const String details = 'İşlem Detayları';
  static const String edit = 'İşlemi Düzenle';
  static const String delete = 'Sil';
  static const String deleteTitle = 'İşlem silinsin mi?';
  static const String deleteMessage =
      'Bu işlem listelerden ve hesaplamalardan kaldırılacaktır.';
  static const String saveChanges = 'Değişiklikleri Kaydet';
  static const String category = 'Kategori';
  static const String type = 'Tür';
  static const String source = 'Kaynak';
  static const String notFound = 'İşlem bulunamadı';
  static const String notFoundDescription =
      'İstenen işlem artık kullanılamıyor.';
  static const String readOnly = 'Bu işlem salt okunurdur';
  static const String readOnlyDescription =
      'Yalnızca manuel gelir ve gider işlemleri düzenlenebilir.';
  static const String income = 'Gelir';
  static const String expense = 'Gider';
  static const String transfer = 'Transfer';
  static const String customerCreditCardPayment = 'K.K. ile Ödm';
  static const String creditCardDebtPayment = 'K.K. Borç Ödm';
  static const String customerCreditExpense = 'Açık Hesap Gider';
  static const String manual = 'Manuel';
  static const String receiptScan = 'Fiş Tarama';
  static const String imported = 'İçe Aktarma';

  static String installmentLabel(int number, int count) {
    return '$number/$count';
  }

  static String transactionType(TransactionType type) {
    return switch (type) {
      TransactionType.income => income,
      TransactionType.expense => expense,
      TransactionType.transfer => transfer,
    };
  }

  static String transactionTypeFor(Transaction transaction) {
    if (transaction.isCustomerCreditCardPayment) {
      return customerCreditCardPayment;
    }
    if (transaction.isCustomerCreditExpense) return customerCreditExpense;
    if (transaction.isCreditCardPayment) return creditCardDebtPayment;
    return transactionType(transaction.transactionType);
  }

  static String transactionSource(TransactionSource source) {
    return switch (source) {
      TransactionSource.manual => manual,
      TransactionSource.receiptScan => receiptScan,
      TransactionSource.import => imported,
    };
  }

  static String creditCardName(String creditCardId) {
    return switch (creditCardId) {
      'credit-card-1' => 'Garanti BBVA Bonus',
      'credit-card-2' => 'İş Bankası Maximum',
      'credit-card-3' => 'Akbank Axess',
      'credit-card-4' => 'Yapı Kredi World',
      _ => creditCardId,
    };
  }
}
