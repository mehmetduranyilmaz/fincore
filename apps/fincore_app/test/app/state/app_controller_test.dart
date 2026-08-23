import 'package:fincore_app/app/state/app_controller.dart';
import 'package:fincore_app/app/state/app_state.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/auth/domain/entities/auth_session.dart';
import 'package:fincore_app/features/auth/domain/entities/user.dart';
import 'package:fincore_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:fincore_app/features/transactions/domain/entities/recurring_expense_plan.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/repositories/recurring_expense_plan_repository.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fincore_app/features/transactions/domain/usecases/realize_due_recurring_expenses.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('initialize sets unauthenticated when session is invalid', () async {
    final repository = _AuthRepository();
    final container = _createContainer(repository);
    addTearDown(container.dispose);

    await container.read(appControllerProvider.notifier).initialize();

    expect(
      container.read(appControllerProvider).status,
      AppStatus.unauthenticated,
    );
  });

  test('initialize sets authenticated when session is valid', () async {
    final repository = _AuthRepository(true);
    final container = _createContainer(repository);
    addTearDown(container.dispose);

    await container.read(appControllerProvider.notifier).initialize();

    expect(
      container.read(appControllerProvider).status,
      AppStatus.authenticated,
    );
  });

  test('login and logout update authentication status', () async {
    final repository = _AuthRepository();
    final container = _createContainer(repository);
    addTearDown(container.dispose);
    final controller = container.read(appControllerProvider.notifier);

    await controller.login(email: 'demo@fincore.app', password: 'password');

    expect(
      container.read(appControllerProvider).status,
      AppStatus.authenticated,
    );

    await controller.logout();

    expect(
      container.read(appControllerProvider).status,
      AppStatus.unauthenticated,
    );
  });

  test('initialize realizes an overdue recurring expense', () async {
    final transactions = _TransactionRepository();
    final container = _createContainer(
      _AuthRepository(true),
      plans: [
        RecurringExpensePlan(
          id: 'overdue-plan',
          accountId: 'account-1',
          creditCardId: null,
          customerId: null,
          amount: 750,
          description: 'Aidat',
          categoryId: null,
          currencyCode: 'TRY',
          firstDueDate: DateTime(2026, 8, 1),
          occurrenceCount: 2,
        ),
      ],
      transactions: transactions,
      clock: () => DateTime(2026, 8, 23),
    );
    addTearDown(container.dispose);

    await container.read(appControllerProvider.notifier).initialize();

    expect(
      container.read(appControllerProvider).status,
      AppStatus.authenticated,
    );
    expect(transactions.transactions, hasLength(1));
    expect(
      transactions.transactions.single.transactionDate,
      DateTime(2026, 8, 1),
    );
  });

  test('logout event updates authentication status', () async {
    final repository = _AuthRepository(true);
    final container = _createContainer(repository);
    addTearDown(container.dispose);

    container.read(appControllerProvider);
    container.read(appControllerProvider.notifier).setAuthenticated();

    await container.read(authSessionManagerProvider).logout();

    expect(
      container.read(appControllerProvider).status,
      AppStatus.unauthenticated,
    );
  });
}

ProviderContainer _createContainer(
  AuthRepository repository, {
  List<RecurringExpensePlan> plans = const [],
  _TransactionRepository? transactions,
  RecurringExpenseRealizationClock? clock,
}) {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      realizeDueRecurringExpensesProvider.overrideWithValue(
        RealizeDueRecurringExpensesUseCase(
          _RecurringExpensePlanRepository(plans),
          transactions ?? _TransactionRepository(),
          clock: clock,
        ),
      ),
    ],
  );
}

final class _RecurringExpensePlanRepository
    implements RecurringExpensePlanRepository {
  const _RecurringExpensePlanRepository(this.plans);

  final List<RecurringExpensePlan> plans;

  @override
  Future<void> create(RecurringExpensePlan plan) async {}

  @override
  Future<void> delete(String planId) async {}

  @override
  Future<List<RecurringExpensePlan>> getPlans() async => plans;

  @override
  Future<void> update(RecurringExpensePlan plan) async {}
}

final class _TransactionRepository implements TransactionRepository {
  final List<Transaction> transactions = [];

  @override
  Future<void> create(Transaction transaction) async {
    transactions.add(transaction);
  }

  @override
  Future<void> createMany(List<Transaction> transactions) async {
    this.transactions.addAll(transactions);
  }

  @override
  Future<Transaction?> getById(String transactionId) async => null;

  @override
  Future<List<Transaction>> getTransactions(TransactionFilter filter) async =>
      List.unmodifiable(transactions);

  @override
  Future<void> update(Transaction transaction) async {}
}

final class _AuthRepository implements AuthRepository {
  _AuthRepository([this._hasValidSession = false]);

  bool _hasValidSession;

  @override
  Future<User?> getCurrentUser() async => null;

  @override
  Future<bool> hasValidSession() async => _hasValidSession;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    _hasValidSession = true;
    return AuthSession(
      accessToken: 'access_token',
      refreshToken: 'refresh_token',
      expiresIn: 3600,
      tokenType: 'Bearer',
      userId: 'user-1',
      email: email,
      fullName: 'Demo User',
    );
  }

  @override
  Future<AuthSession> refresh() async {
    return login(email: 'demo@fincore.app', password: 'password');
  }

  @override
  Future<void> logout() async {
    _hasValidSession = false;
  }
}
