import 'package:fincore_app/features/categories/domain/entities/category_type.dart';

final class Category {
  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });

  final String id;
  final String name;
  final String icon;
  final int color;
  final CategoryType type;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Category &&
            id == other.id &&
            name == other.name &&
            icon == other.icon &&
            color == other.color &&
            type == other.type;
  }

  @override
  int get hashCode => Object.hash(id, name, icon, color, type);
}
