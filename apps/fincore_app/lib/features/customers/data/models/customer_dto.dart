import 'package:fincore_app/features/customers/domain/entities/customer.dart';

final class CustomerDto {
  const CustomerDto(this.customer);

  factory CustomerDto.fromJson(Map<String, Object?> json) {
    return CustomerDto(
      Customer(
        id: json['id']! as String,
        name: json['name']! as String,
        openingBalance: (json['openingBalance']! as num).toDouble(),
        currencyCode: json['currencyCode']! as String,
        isArchived: json['isArchived']! as bool,
      ),
    );
  }

  final Customer customer;

  Map<String, Object?> toJson() => {
    'id': customer.id,
    'name': customer.name,
    'openingBalance': customer.openingBalance,
    'currencyCode': customer.currencyCode,
    'isArchived': customer.isArchived,
  };
}
