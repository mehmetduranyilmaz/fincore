import 'package:fincore_app/core/config/environment.dart';
import 'package:fincore_app/core/network/dio_provider.dart';
import 'package:fincore_app/core/storage/secure_storage_service.dart';
import 'package:fincore_app/core/storage/token_storage.dart';
import 'package:fincore_app/features/accounts/data/datasources/account_mock_data_source.dart';
import 'package:fincore_app/features/accounts/data/datasources/account_local_data_source.dart';
import 'package:fincore_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:fincore_app/features/auth/data/datasources/auth_local_data_source_impl.dart';
import 'package:fincore_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:fincore_app/features/auth/data/datasources/auth_remote_data_source_impl.dart';
import 'package:fincore_app/features/auth/data/datasources/dev_auth_remote_data_source.dart';
import 'package:fincore_app/features/auth/data/datasources/dev_credential_store.dart';
import 'package:fincore_app/features/budgets/data/datasources/budget_mock_data_source.dart';
import 'package:fincore_app/features/budgets/data/datasources/budget_local_data_source.dart';
import 'package:fincore_app/features/categories/data/datasources/category_mock_data_source.dart';
import 'package:fincore_app/features/categories/data/datasources/category_local_data_source.dart';
import 'package:fincore_app/features/credit_cards/data/datasources/credit_card_mock_data_source.dart';
import 'package:fincore_app/features/credit_cards/data/datasources/credit_card_local_data_source.dart';
import 'package:fincore_app/features/credit_cards/data/datasources/credit_card_statement_local_data_source.dart';
import 'package:fincore_app/features/customers/data/datasources/customer_local_data_source.dart';
import 'package:fincore_app/features/transactions/data/datasources/transaction_mock_data_source.dart';
import 'package:fincore_app/features/transactions/data/datasources/transaction_local_data_source.dart';
import 'package:fincore_app/features/transactions/data/services/receipt_scanner_impl.dart';
import 'package:fincore_app/features/transactions/domain/services/receipt_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>(
  (ref) => AuthLocalDataSourceImpl(ref.watch(tokenStorageProvider)),
);

final Provider<AuthRemoteDataSource> authRemoteDataSourceProvider =
    Provider<AuthRemoteDataSource>(
      (ref) => switch (ref.watch(environmentProvider)) {
        Environment.dev => DevAuthRemoteDataSource(
          ref.watch(devCredentialStoreProvider),
        ),
        Environment.test || Environment.prod => AuthRemoteDataSourceImpl(
          apiClient: ref.watch(apiClientProvider),
        ),
      },
    );

final devCredentialStoreProvider = Provider<DevCredentialStore>(
  (ref) => DevCredentialStore(
    SecureCredentialKeyValueStore(ref.watch(secureStorageServiceProvider)),
  ),
);

final accountLocalDataSourceProvider = Provider<AccountLocalDataSource>(
  (ref) => AccountLocalDataSource(ref.watch(secureStorageServiceProvider)),
);

final Provider<AccountDataSource> accountDataSourceProvider =
    Provider<AccountDataSource>(
      (ref) => ref.watch(accountLocalDataSourceProvider),
    );

final Provider<AccountCommandDataSource> accountCommandDataSourceProvider =
    Provider<AccountCommandDataSource>(
      (ref) => ref.watch(accountLocalDataSourceProvider),
    );

final creditCardLocalDataSourceProvider = Provider<CreditCardLocalDataSource>(
  (ref) => CreditCardLocalDataSource(ref.watch(secureStorageServiceProvider)),
);

final creditCardStatementLocalDataSourceProvider =
    Provider<CreditCardStatementLocalDataSource>(
      (ref) => CreditCardStatementLocalDataSource(
        ref.watch(secureStorageServiceProvider),
      ),
    );

final Provider<CreditCardStatementDataSource>
creditCardStatementDataSourceProvider = Provider<CreditCardStatementDataSource>(
  (ref) => ref.watch(creditCardStatementLocalDataSourceProvider),
);

final customerLocalDataSourceProvider = Provider<CustomerLocalDataSource>(
  (ref) => CustomerLocalDataSource(ref.watch(secureStorageServiceProvider)),
);

final Provider<CustomerDataSource> customerDataSourceProvider =
    Provider<CustomerDataSource>(
      (ref) => ref.watch(customerLocalDataSourceProvider),
    );

final Provider<CreditCardDataSource> creditCardDataSourceProvider =
    Provider<CreditCardDataSource>(
      (ref) => ref.watch(creditCardLocalDataSourceProvider),
    );

final Provider<CreditCardCommandDataSource>
creditCardCommandDataSourceProvider = Provider<CreditCardCommandDataSource>(
  (ref) => ref.watch(creditCardLocalDataSourceProvider),
);

final transactionLocalDataSourceProvider = Provider<TransactionLocalDataSource>(
  (ref) => TransactionLocalDataSource(ref.watch(secureStorageServiceProvider)),
);

final Provider<TransactionDataSource> transactionDataSourceProvider =
    Provider<TransactionDataSource>(
      (ref) => ref.watch(transactionLocalDataSourceProvider),
    );

final Provider<InstallmentTransactionDataSource>
installmentTransactionDataSourceProvider =
    Provider<InstallmentTransactionDataSource>(
      (ref) => ref.watch(transactionLocalDataSourceProvider),
    );

final imagePickerProvider = Provider<ImagePicker>((ref) => ImagePicker());

final Provider<ReceiptImagePicker> receiptImagePickerProvider =
    Provider<ReceiptImagePicker>(
      (ref) => ImagePickerReceiptImagePicker(ref.watch(imagePickerProvider)),
    );

final Provider<ReceiptTextRecognizer> receiptTextRecognizerProvider =
    Provider<ReceiptTextRecognizer>(
      (ref) => const MlKitReceiptTextRecognizer(),
    );

final categoryLocalDataSourceProvider = Provider<CategoryLocalDataSource>(
  (ref) => CategoryLocalDataSource(ref.watch(secureStorageServiceProvider)),
);

final Provider<CategoryDataSource> categoryDataSourceProvider =
    Provider<CategoryDataSource>(
      (ref) => ref.watch(categoryLocalDataSourceProvider),
    );

final budgetLocalDataSourceProvider = Provider<BudgetLocalDataSource>(
  (ref) => BudgetLocalDataSource(ref.watch(secureStorageServiceProvider)),
);

final Provider<BudgetDataSource> budgetDataSourceProvider =
    Provider<BudgetDataSource>(
      (ref) => ref.watch(budgetLocalDataSourceProvider),
    );
