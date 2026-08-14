import 'package:fincore_app/core/di/datasources.dart';
import 'package:fincore_app/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:fincore_app/features/accounts/data/repositories/account_command_repository_impl.dart';
import 'package:fincore_app/features/accounts/domain/repositories/account_command_repository.dart';
import 'package:fincore_app/features/accounts/domain/repositories/account_repository.dart';
import 'package:fincore_app/features/accounts/domain/repositories/account_usage_repository.dart';
import 'package:fincore_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fincore_app/features/auth/data/repositories/dev_user_credentials_repository.dart';
import 'package:fincore_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:fincore_app/features/auth/domain/repositories/user_credentials_repository.dart';
import 'package:fincore_app/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:fincore_app/features/budgets/domain/repositories/budget_repository.dart';
import 'package:fincore_app/features/categories/data/repositories/category_repository_impl.dart';
import 'package:fincore_app/features/categories/domain/repositories/category_repository.dart';
import 'package:fincore_app/features/categories/domain/repositories/category_usage_repository.dart';
import 'package:fincore_app/features/credit_cards/data/repositories/credit_card_repository_impl.dart';
import 'package:fincore_app/features/credit_cards/data/repositories/credit_card_command_repository_impl.dart';
import 'package:fincore_app/features/credit_cards/data/repositories/credit_card_statement_repository_impl.dart';
import 'package:fincore_app/features/credit_cards/data/repositories/credit_card_usage_repository_impl.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_command_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_statement_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_usage_repository.dart';
import 'package:fincore_app/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:fincore_app/features/customers/domain/repositories/customer_repository.dart';
import 'package:fincore_app/features/customers/domain/repositories/customer_usage_repository.dart';
import 'package:fincore_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:fincore_app/features/transactions/data/repositories/transaction_reference_usage_repository_impl.dart';
import 'package:fincore_app/features/transactions/data/repositories/installment_transaction_repository_impl.dart';
import 'package:fincore_app/features/transactions/domain/repositories/installment_transaction_repository.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_deletion_repository.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>(
      (ref) => AuthRepositoryImpl(
        localDataSource: ref.watch(authLocalDataSourceProvider),
        remoteDataSource: ref.watch(authRemoteDataSourceProvider),
      ),
    );

final Provider<UserCredentialsRepository> userCredentialsRepositoryProvider =
    Provider<UserCredentialsRepository>(
      (ref) =>
          DevUserCredentialsRepository(ref.watch(devCredentialStoreProvider)),
    );

final Provider<AccountRepository> accountRepositoryProvider =
    Provider<AccountRepository>(
      (ref) => AccountRepositoryImpl(ref.watch(accountDataSourceProvider)),
    );

final Provider<AccountCommandRepository> accountCommandRepositoryProvider =
    Provider<AccountCommandRepository>(
      (ref) => AccountCommandRepositoryImpl(
        ref.watch(accountCommandDataSourceProvider),
      ),
    );

final Provider<CreditCardRepository> creditCardRepositoryProvider =
    Provider<CreditCardRepository>(
      (ref) =>
          CreditCardRepositoryImpl(ref.watch(creditCardDataSourceProvider)),
    );

final Provider<CustomerRepository> customerRepositoryProvider =
    Provider<CustomerRepository>(
      (ref) => CustomerRepositoryImpl(ref.watch(customerDataSourceProvider)),
    );

final Provider<CreditCardCommandRepository>
creditCardCommandRepositoryProvider = Provider<CreditCardCommandRepository>(
  (ref) => CreditCardCommandRepositoryImpl(
    ref.watch(creditCardCommandDataSourceProvider),
  ),
);

final Provider<CreditCardStatementRepository>
creditCardStatementRepositoryProvider = Provider<CreditCardStatementRepository>(
  (ref) => CreditCardStatementRepositoryImpl(
    ref.watch(creditCardStatementDataSourceProvider),
  ),
);

final Provider<CreditCardUsageRepository> creditCardUsageRepositoryProvider =
    Provider<CreditCardUsageRepository>(
      (ref) => CreditCardUsageRepositoryImpl(
        ref.watch(transactionDataSourceProvider),
        ref.watch(creditCardStatementDataSourceProvider),
      ),
    );

final Provider<TransactionRepository> transactionRepositoryProvider =
    Provider<TransactionRepository>(
      (ref) =>
          TransactionRepositoryImpl(ref.watch(transactionDataSourceProvider)),
    );

final Provider<TransactionDeletionRepository>
transactionDeletionRepositoryProvider = Provider<TransactionDeletionRepository>(
  (ref) => TransactionRepositoryImpl(ref.watch(transactionDataSourceProvider)),
);

final Provider<AccountUsageRepository> accountUsageRepositoryProvider =
    Provider<AccountUsageRepository>(
      (ref) =>
          AccountUsageRepositoryImpl(ref.watch(transactionDataSourceProvider)),
    );

final Provider<CategoryUsageRepository> categoryUsageRepositoryProvider =
    Provider<CategoryUsageRepository>(
      (ref) =>
          CategoryUsageRepositoryImpl(ref.watch(transactionDataSourceProvider)),
    );

final Provider<CustomerUsageRepository> customerUsageRepositoryProvider =
    Provider<CustomerUsageRepository>(
      (ref) =>
          CustomerUsageRepositoryImpl(ref.watch(transactionDataSourceProvider)),
    );

final Provider<InstallmentTransactionRepository>
installmentTransactionRepositoryProvider =
    Provider<InstallmentTransactionRepository>(
      (ref) => InstallmentTransactionRepositoryImpl(
        ref.watch(installmentTransactionDataSourceProvider),
      ),
    );

final Provider<CategoryRepository> categoryRepositoryProvider =
    Provider<CategoryRepository>(
      (ref) => CategoryRepositoryImpl(ref.watch(categoryDataSourceProvider)),
    );

final Provider<BudgetRepository> budgetRepositoryProvider =
    Provider<BudgetRepository>(
      (ref) => BudgetRepositoryImpl(ref.watch(budgetDataSourceProvider)),
    );
