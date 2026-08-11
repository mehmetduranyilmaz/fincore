import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_payment_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final creditCardPaymentCalendarProvider =
    FutureProvider<CreditCardPaymentCalendar>((ref) {
      return ref.watch(getCreditCardPaymentCalendarProvider).execute();
    });
