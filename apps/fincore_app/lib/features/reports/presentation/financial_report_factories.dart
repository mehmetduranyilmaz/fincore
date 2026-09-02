import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/reporting/financial_pdf_report.dart';
import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/domain/entities/account_movement.dart';
import 'package:fincore_app/features/categories/domain/entities/category.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_payment_calendar.dart';
import 'package:fincore_app/features/customers/domain/entities/customer.dart';
import 'package:fincore_app/features/customers/domain/entities/customer_movement.dart';
import 'package:fincore_app/features/customers/presentation/constants/customer_strings.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/presentation/constants/transaction_strings.dart';
import 'package:fincore_app/features/transactions/presentation/formatters/payment_source_formatter.dart';

abstract final class FinancialReportFactories {
  static FinancialPdfReport accountMovements({
    required Account account,
    required List<AccountMovement> movements,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    var incoming = 0.0;
    var outgoing = 0.0;
    for (final item in movements) {
      final delta = _accountMovementDelta(item.transaction);
      if (delta >= 0) {
        incoming += delta;
      } else {
        outgoing += delta.abs();
      }
    }
    final currentBalance = movements.isEmpty
        ? account.openingBalance
        : movements.first.balanceAfterMovement;
    return FinancialPdfReport(
      title: '${account.name} - Hesap Ekstresi',
      subtitle:
          '${AppFormatters.date(startDate)} - ${AppFormatters.date(endDate)} hesap hareketleri',
      metrics: [
        FinancialReportMetric(
          label: 'Dönem sonu bakiye',
          value: AppFormatters.currency(
            currentBalance,
            currencyCode: account.currencyCode,
          ),
        ),
        FinancialReportMetric(
          label: 'Toplam giriş',
          value: AppFormatters.currency(
            incoming,
            currencyCode: account.currencyCode,
          ),
        ),
        FinancialReportMetric(
          label: 'Toplam çıkış',
          value: AppFormatters.currency(
            outgoing,
            currencyCode: account.currencyCode,
          ),
        ),
      ],
      columns: const [
        FinancialReportColumn(label: 'Tarih', flex: 1.1),
        FinancialReportColumn(label: 'Açıklama', flex: 2.5),
        FinancialReportColumn(label: 'Tür', flex: 1.2),
        FinancialReportColumn(
          label: 'Tutar',
          flex: 1.4,
          alignment: FinancialReportAlignment.right,
        ),
        FinancialReportColumn(
          label: 'Bakiye',
          flex: 1.5,
          alignment: FinancialReportAlignment.right,
        ),
      ],
      rows: [
        for (final item in movements)
          [
            AppFormatters.date(item.transaction.transactionDate),
            item.transaction.merchant,
            _accountMovementType(item.transaction.transactionType),
            AppFormatters.currency(
              _accountMovementDelta(item.transaction),
              currencyCode: account.currencyCode,
            ),
            AppFormatters.currency(
              item.balanceAfterMovement,
              currencyCode: account.currencyCode,
            ),
          ],
      ],
      note: 'Ekstre, seçilen tarih aralığındaki hesap hareketlerini içerir.',
    );
  }

  static FinancialPdfReport transactions({
    required List<Transaction> transactions,
    required List<Account> accounts,
    required List<CreditCard> creditCards,
    required List<Customer> customers,
    required List<Category> categories,
  }) {
    final accountById = {for (final item in accounts) item.id: item};
    final cardById = {for (final item in creditCards) item.id: item};
    final customerById = {for (final item in customers) item.id: item};
    final categoryById = {for (final item in categories) item.id: item};
    final incomeTotals = <String, double>{};
    final expenseTotals = <String, double>{};

    for (final transaction in transactions) {
      final currency = _transactionCurrency(
        transaction,
        accountById,
        cardById,
        customerById,
      );
      if (transaction.transactionType == TransactionType.income &&
          !transaction.isCreditCardPayment) {
        incomeTotals.update(
          currency,
          (value) => value + transaction.amount.abs(),
          ifAbsent: () => transaction.amount.abs(),
        );
      } else if (transaction.isActualExpense) {
        expenseTotals.update(
          currency,
          (value) => value + transaction.amount.abs(),
          ifAbsent: () => transaction.amount.abs(),
        );
      }
    }

    return FinancialPdfReport(
      title: 'İşlemler Raporu',
      subtitle: 'Ekranda uygulanan filtrelere göre işlem dökümü',
      metrics: [
        FinancialReportMetric(
          label: 'Kayıt sayısı',
          value: transactions.length.toString(),
        ),
        FinancialReportMetric(
          label: 'Toplam gelir',
          value: _currencyTotals(incomeTotals),
        ),
        FinancialReportMetric(
          label: 'Toplam gider',
          value: _currencyTotals(expenseTotals),
        ),
      ],
      columns: const [
        FinancialReportColumn(label: 'Tarih', flex: 1.05),
        FinancialReportColumn(label: 'Açıklama', flex: 2.3),
        FinancialReportColumn(label: 'Tür', flex: 1.15),
        FinancialReportColumn(label: 'Kategori', flex: 1.35),
        FinancialReportColumn(label: 'Kaynak', flex: 1.8),
        FinancialReportColumn(
          label: 'Tutar',
          flex: 1.3,
          alignment: FinancialReportAlignment.right,
        ),
      ],
      rows: [
        for (final transaction in transactions)
          [
            AppFormatters.date(transaction.transactionDate),
            transaction.merchant,
            TransactionStrings.transactionTypeFor(transaction),
            categoryById[transaction.categoryId]?.name ?? '-',
            _sourceLabel(transaction, accountById, cardById, customerById),
            AppFormatters.currency(
              transaction.amount.abs(),
              currencyCode: _transactionCurrency(
                transaction,
                accountById,
                cardById,
                customerById,
              ),
            ),
          ],
      ],
      note:
          'Bu rapor, İşlemler ekranında o anda görünen filtrelenmiş kayıtları içerir.',
    );
  }

  static FinancialPdfReport customerMovements({
    required Customer customer,
    required List<CustomerMovement> movements,
  }) {
    final balance = movements.isEmpty
        ? customer.openingBalance
        : movements.first.balanceAfterMovement;
    var debit = 0.0;
    var credit = 0.0;
    for (final item in movements) {
      final delta = item.transaction.customerBalanceDelta!;
      if (delta > 0) {
        debit += delta;
      } else {
        credit += delta.abs();
      }
    }
    return FinancialPdfReport(
      title: '${customer.name} - Müşteri Hareketleri',
      subtitle: 'Cari hesap hareketleri ve hareket sonrası bakiye dökümü',
      metrics: [
        FinancialReportMetric(
          label: 'Güncel bakiye',
          value:
              '${AppFormatters.currency(balance.abs(), currencyCode: customer.currencyCode)} ${_balanceCode(balance)}',
        ),
        FinancialReportMetric(
          label: 'Borçlandıran hareketler',
          value: AppFormatters.currency(
            debit,
            currencyCode: customer.currencyCode,
          ),
        ),
        FinancialReportMetric(
          label: 'Azaltan hareketler',
          value: AppFormatters.currency(
            credit,
            currencyCode: customer.currencyCode,
          ),
        ),
      ],
      columns: const [
        FinancialReportColumn(label: 'Tarih', flex: 1.05),
        FinancialReportColumn(label: 'Açıklama', flex: 2.3),
        FinancialReportColumn(label: 'Hareket', flex: 1.35),
        FinancialReportColumn(label: 'Kaynak', flex: 1.25),
        FinancialReportColumn(
          label: 'Tutar',
          flex: 1.3,
          alignment: FinancialReportAlignment.right,
        ),
        FinancialReportColumn(
          label: 'Bakiye',
          flex: 1.45,
          alignment: FinancialReportAlignment.right,
        ),
      ],
      rows: [
        for (final item in movements)
          [
            AppFormatters.date(item.transaction.transactionDate),
            item.transaction.merchant,
            _customerMovementLabel(item.transaction),
            item.transaction.isCustomerCreditExpense
                ? TransactionStrings.openAccount
                : item.transaction.accountId != null
                ? 'Kasa/Banka'
                : 'Kredi Kartı',
            AppFormatters.currency(
              item.transaction.customerBalanceDelta!.abs(),
              currencyCode: customer.currencyCode,
            ),
            '${AppFormatters.currency(item.balanceAfterMovement.abs(), currencyCode: customer.currencyCode)} ${_balanceCode(item.balanceAfterMovement)}',
          ],
      ],
      note:
          'B: müşteri size borçlu, A: siz müşteriye borçlusunuz, -: hesap kapalıdır.',
    );
  }

  static FinancialPdfReport paymentCalendar(
    CreditCardPaymentCalendar calendar,
  ) {
    final rows = <List<String>>[];
    var monthCount = 0;
    var plannedCount = 0;
    for (final year in calendar.years) {
      for (final month in year.months) {
        monthCount++;
        plannedCount += month.plannedExpenseCount;
        rows.add([
          month.periodLabel,
          month.confirmedTransactionCount.toString(),
          month.plannedExpenseCount.toString(),
          _currencyTotals(month.totalsByCurrency),
        ]);
        for (final detail in month.details) {
          rows.add([
            '  ${detail.label}',
            detail.confirmedTransactionCount.toString(),
            detail.plannedExpenseCount.toString(),
            _currencyTotals(detail.totalsByCurrency),
          ]);
        }
      }
      rows.add([
        '${year.year} Yılı Toplamı',
        '-',
        '-',
        _currencyTotals(year.totalsByCurrency),
      ]);
    }
    return FinancialPdfReport(
      title: 'Aylık Ödeme Takvimi',
      subtitle: 'Kredi kartı işlemleri ve planlanan tekrarlayan giderler',
      landscape: false,
      metrics: [
        FinancialReportMetric(
          label: 'Yıl sayısı',
          value: calendar.years.length.toString(),
        ),
        FinancialReportMetric(label: 'Ay sayısı', value: monthCount.toString()),
        FinancialReportMetric(
          label: 'Planlanan gider',
          value: plannedCount.toString(),
        ),
      ],
      columns: const [
        FinancialReportColumn(label: 'Dönem', flex: 1.6),
        FinancialReportColumn(
          label: 'İşlem/Taksit',
          flex: 1.2,
          alignment: FinancialReportAlignment.center,
        ),
        FinancialReportColumn(
          label: 'Planlanan',
          flex: 1.15,
          alignment: FinancialReportAlignment.center,
        ),
        FinancialReportColumn(
          label: 'Toplam Ödeme',
          flex: 2,
          alignment: FinancialReportAlignment.right,
        ),
      ],
      rows: rows,
      note:
          'Vadesi gelen tekrarlayan giderler gerçek harekete dönüşür; gelecek vadeler planlanan olarak gösterilir.',
    );
  }

  static String _transactionCurrency(
    Transaction transaction,
    Map<String, Account> accounts,
    Map<String, CreditCard> cards,
    Map<String, Customer> customers,
  ) {
    return accounts[transaction.accountId]?.currencyCode ??
        cards[transaction.creditCardId]?.currencyCode ??
        customers[transaction.customerId]?.currencyCode ??
        'TRY';
  }

  static String _sourceLabel(
    Transaction transaction,
    Map<String, Account> accounts,
    Map<String, CreditCard> cards,
    Map<String, Customer> customers,
  ) {
    final account = accounts[transaction.accountId];
    if (account != null) return PaymentSourceFormatter.account(account);
    final card = cards[transaction.creditCardId];
    if (card != null) return PaymentSourceFormatter.creditCard(card);
    final customer = customers[transaction.customerId];
    if (customer != null) return 'AH-${customer.name}';
    return '-';
  }

  static String _customerMovementLabel(Transaction transaction) {
    if (transaction.isCustomerCreditExpense) {
      return TransactionStrings.customerCreditExpense;
    }
    final isCollection =
        transaction.isCustomerPayment && transaction.customerBalanceDelta! < 0;
    return isCollection ? CustomerStrings.collection : CustomerStrings.payment;
  }

  static double _accountMovementDelta(Transaction transaction) =>
      switch (transaction.transactionType) {
        TransactionType.income => transaction.amount.abs(),
        TransactionType.expense => -transaction.amount.abs(),
        TransactionType.transfer => transaction.amount,
      };

  static String _accountMovementType(TransactionType type) => switch (type) {
    TransactionType.income => 'Gelir',
    TransactionType.expense => 'Gider',
    TransactionType.transfer => 'Transfer',
  };

  static String _balanceCode(double balance) {
    if (balance > 0) return CustomerStrings.debtorCode;
    if (balance < 0) return CustomerStrings.creditorCode;
    return CustomerStrings.settledCode;
  }

  static String _currencyTotals(Map<String, double> totals) {
    if (totals.isEmpty) return '-';
    final codes = totals.keys.toList()..sort();
    return [
      for (final code in codes)
        AppFormatters.currency(totals[code]!, currencyCode: code),
    ].join(' / ');
  }
}
