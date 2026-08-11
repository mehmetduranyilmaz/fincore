abstract final class CreditCardStrings {
  static const String title = 'Kredi Kartları';
  static const String create = 'Kart Ekle';
  static const String edit = 'Kartı Düzenle';
  static const String delete = 'Sil';
  static const String cancel = 'Vazgeç';
  static const String save = 'Kaydet';
  static const String bankName = 'Banka';
  static const String selectBank = 'Banka seçin';
  static const String selectBankValidation = 'Bir banka seçin.';
  static const String cardName = 'Kart Adı';
  static const String lastFourDigits = 'Kartın Son 4 Hanesi';
  static const String currency = 'Para Birimi';
  static const String archiveCard = 'Kartı arşivle';
  static const String archiveCardDescription =
      'Arşivlenen kartlar listede kalır ancak pasif olarak işaretlenir.';
  static const String requiredField = 'Bu alan zorunludur.';
  static const String invalidLastFourDigits = '4 rakam girin.';
  static const String invalidCreditLimit = 'Geçerli bir kart limiti girin.';
  static const String deleteTitle = 'Kredi kartı silinsin mi?';
  static const String deleteMessage =
      'Bu kart cihazdaki kart listenizden kalıcı olarak silinecek.';
  static const String cardNotFound = 'Kredi kartı bulunamadı.';
  static const String archived = 'Arşivlendi';
  static const String creditLimit = 'Kart Limiti';
  static const String currentDebt = 'Güncel Borç';
  static const String availableLimit = 'Kullanılabilir Limit';
  static const String statementDay = 'Beklenen Kesim Günü';
  static const String dueDay = 'Son Ödeme Günü';
  static const String noCreditCards = 'Henüz kredi kartı yok';
  static const String noCreditCardsDescription =
      'Kredi kartlarınız burada görünecek.';
  static const String unableToLoad = 'Kredi kartları yüklenemedi.';
  static const String retry = 'Tekrar Dene';
  static const String balanceUnavailable = 'Bakiye bilgisi kullanılamıyor';
  static const String statements = 'Ekstreler';
  static const String createStatement = 'Ekstre Oluştur';
  static const String saveStatement = 'Ekstreyi Kaydet';
  static const String statementDate = 'Ekstre tarihi';
  static const String statementDueDate = 'Son ödeme';
  static const String statementTotal = 'Ekstre toplamı';
  static const String selectedTransactions = 'Seçilen hareket';
  static const String selectAll = 'Tümünü seç';
  static const String clearSelection = 'Seçimi kaldır';
  static const String statementSelectionHint =
      'Kesim tarihinden önceki hareketler öneri olarak seçildi. '
      'Kesim günü hareketlerini bankanızın ekstresine göre kontrol edin.';
  static const String noStatements = 'Henüz manuel ekstre yok';
  static const String noStatementsDescription =
      'Ekstre yalnızca siz hareketleri seçip kaydettiğinizde oluşturulur.';
  static const String noStatementCandidates = 'Eklenecek hareket yok';
  static const String noStatementCandidatesDescription =
      'Bu tarihe kadar ekstreye eklenmemiş kart hareketi bulunmuyor.';
  static const String statementsUnableToLoad = 'Ekstreler yüklenemedi.';
  static const String currentPeriodTransactions = 'Dönem İçi Hareketler';
  static const String futureInstallments = 'Gelecek Aylardaki Taksitler';
  static const String noCurrentMovements = 'Dönem içi hareket yok';
  static const String noCurrentMovementsDescription =
      'Henüz ekstreye alınmamış gerçekleşmiş kart hareketi bulunmuyor.';
  static const String noFutureInstallments = 'Gelecek taksit yok';
  static const String noFutureInstallmentsDescription =
      'Sıradaki kesilecek ekstreden sonraya kalan taksit bulunmuyor.';
  static const String movementsUnableToLoad = 'Kart hareketleri yüklenemedi.';
  static const String installmentsUnableToLoad = 'Taksitler yüklenemedi.';
  static const String makePayment = 'Kredi Kartı Borcu Öde';
  static const String paymentCalendar = 'Aylık Ödeme Takvimi';
  static const String paymentCalendarHint =
      'Bu ay ve sonraki aylardaki kredi kartı harcamaları, işlem ve taksit '
      'ayına göre gösterilir. Farklı para birimleri birbirine eklenmez.';
  static const String yearTotal = 'Yıl toplamı';
  static const String noScheduledPayments = 'Planlanmış ödeme yok';
  static const String noScheduledPaymentsDescription =
      'Bu ay veya sonraki aylara ait kredi kartı harcaması bulunmuyor.';
  static const String paymentCalendarUnableToLoad =
      'Ödeme takvimi yüklenemedi.';

  static String scheduledTransactionCount(int count) => '$count işlem/taksit';
}
