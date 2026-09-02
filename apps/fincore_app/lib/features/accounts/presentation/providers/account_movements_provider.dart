import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/accounts/domain/entities/account_movement.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef AccountMovementQuery = ({
  String accountId,
  DateTime startDate,
  DateTime endDate,
});

final accountMovementsProvider =
    FutureProvider.family<List<AccountMovement>, AccountMovementQuery>((
      ref,
      query,
    ) {
      return ref
          .watch(getAccountMovementsProvider)
          .execute(
            accountId: query.accountId,
            startDate: query.startDate,
            endDate: query.endDate,
          );
    });
