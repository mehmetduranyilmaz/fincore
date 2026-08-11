import 'package:fincore_app/features/accounts/domain/repositories/account_usage_repository.dart';
import 'package:fincore_app/features/categories/domain/repositories/category_usage_repository.dart';
import 'package:fincore_app/features/customers/domain/repositories/customer_usage_repository.dart';
import 'package:fincore_app/features/transactions/data/datasources/transaction_mock_data_source.dart';

final class AccountUsageRepositoryImpl implements AccountUsageRepository {
  const AccountUsageRepositoryImpl(this._dataSource);

  final TransactionDataSource _dataSource;

  @override
  Future<bool> hasUsage(String accountId) {
    return _dataSource.hasAnyAccountMovement(accountId);
  }
}

final class CategoryUsageRepositoryImpl implements CategoryUsageRepository {
  const CategoryUsageRepositoryImpl(this._dataSource);

  final TransactionDataSource _dataSource;

  @override
  Future<bool> hasUsage(String categoryId) {
    return _dataSource.hasAnyCategoryMovement(categoryId);
  }
}

final class CustomerUsageRepositoryImpl implements CustomerUsageRepository {
  const CustomerUsageRepositoryImpl(this._dataSource);

  final TransactionDataSource _dataSource;

  @override
  Future<bool> hasUsage(String customerId) {
    return _dataSource.hasAnyCustomerMovement(customerId);
  }
}
