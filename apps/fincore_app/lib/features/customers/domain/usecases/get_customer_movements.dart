import 'package:fincore_app/features/customers/domain/entities/customer_movement.dart';
import 'package:fincore_app/features/customers/domain/errors/customer_operation_exception.dart';
import 'package:fincore_app/features/customers/domain/repositories/customer_repository.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';

final class GetCustomerMovementsUseCase {
  const GetCustomerMovementsUseCase(
    this._transactionRepository,
    this._customerRepository,
  );

  final TransactionRepository _transactionRepository;
  final CustomerRepository _customerRepository;

  Future<List<CustomerMovement>> execute(String customerId) async {
    final customer = await _customerRepository.getById(customerId);
    if (customer == null) {
      throw const CustomerOperationException('Müşteri bulunamadı.');
    }
    final transactions = await _transactionRepository.getTransactions(
      TransactionFilter(),
    );
    final chronological =
        transactions
            .where(
              (transaction) =>
                  !transaction.isDeleted &&
                  transaction.customerId == customerId &&
                  transaction.hasCustomerLedgerMovement,
            )
            .toList()
          ..sort(_compareChronologically);

    var runningBalance = customer.openingBalance;
    final movements = <CustomerMovement>[];
    for (final transaction in chronological) {
      runningBalance += transaction.customerBalanceDelta!;
      if (runningBalance.abs() < 0.000001) runningBalance = 0;
      movements.add(
        CustomerMovement(
          transaction: transaction,
          balanceAfterMovement: runningBalance,
        ),
      );
    }
    return List.unmodifiable(movements);
  }

  static int _compareChronologically(Transaction left, Transaction right) {
    final byDate = left.transactionDate.compareTo(right.transactionDate);
    if (byDate != 0) return byDate;
    final byCreation = _createdOrder(
      left.id,
    ).compareTo(_createdOrder(right.id));
    return byCreation != 0 ? byCreation : left.id.compareTo(right.id);
  }

  static int _createdOrder(String id) {
    final match = RegExp(r'\d{13,}').firstMatch(id);
    return int.tryParse(match?.group(0) ?? '') ?? 0;
  }
}
