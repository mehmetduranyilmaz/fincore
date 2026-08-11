import 'package:fincore_app/features/categories/domain/entities/category.dart';
import 'package:fincore_app/features/categories/domain/entities/category_type.dart';

final class CategoryDto {
  const CategoryDto(this.category);

  factory CategoryDto.fromJson(Map<String, Object?> json) {
    return CategoryDto(
      Category(
        id: json['id']! as String,
        name: json['name']! as String,
        icon: json['icon']! as String,
        color: json['color']! as int,
        type: CategoryType.values.byName(json['type']! as String),
      ),
    );
  }

  final Category category;

  Map<String, Object?> toJson() => {
    'id': category.id,
    'name': category.name,
    'icon': category.icon,
    'color': category.color,
    'type': category.type.name,
  };
}
