import 'package:fincore_app/features/categories/domain/entities/category.dart';
import 'package:fincore_app/features/categories/domain/entities/category_type.dart';

abstract interface class CategoryDataSource {
  Future<List<Category>> getAll();

  Future<Category?> getById(String categoryId);

  Future<void> insert(Category category);

  Future<void> replace(Category category);

  Future<void> remove(String categoryId);
}

final class CategoryMockDataSource implements CategoryDataSource {
  CategoryMockDataSource({List<Category>? seed})
    : _categories = List.of(seed ?? defaultCategories);

  final List<Category> _categories;

  @override
  Future<List<Category>> getAll() async {
    return List.unmodifiable(_categories);
  }

  @override
  Future<Category?> getById(String categoryId) async {
    for (final category in _categories) {
      if (category.id == categoryId) {
        return category;
      }
    }
    return null;
  }

  @override
  Future<void> insert(Category category) async {
    if (_categories.any((item) => item.id == category.id)) {
      throw StateError('Category already exists.');
    }
    _categories.add(category);
  }

  @override
  Future<void> replace(Category category) async {
    final index = _categories.indexWhere((item) => item.id == category.id);
    if (index < 0) {
      throw StateError('Category not found.');
    }
    if (_categories[index].type != category.type) {
      throw StateError('Category type cannot be changed.');
    }
    _categories[index] = category;
  }

  @override
  Future<void> remove(String categoryId) async {
    final index = _categories.indexWhere((item) => item.id == categoryId);
    if (index < 0) {
      throw StateError('Category not found.');
    }
    _categories.removeAt(index);
  }

  static const List<Category> defaultCategories = [
    Category(
      id: 'category-grocery',
      name: 'Groceries',
      icon: 'shopping_cart',
      color: 0xFF2E7D32,
      type: CategoryType.expense,
    ),
    Category(
      id: 'category-transport',
      name: 'Transportation',
      icon: 'directions_car',
      color: 0xFF1565C0,
      type: CategoryType.expense,
    ),
    Category(
      id: 'category-subscription',
      name: 'Subscriptions',
      icon: 'subscriptions',
      color: 0xFF6A1B9A,
      type: CategoryType.expense,
    ),
    Category(
      id: 'category-entertainment',
      name: 'Entertainment',
      icon: 'movie',
      color: 0xFFAD1457,
      type: CategoryType.expense,
    ),
    Category(
      id: 'category-utilities',
      name: 'Utilities',
      icon: 'bolt',
      color: 0xFFF57F17,
      type: CategoryType.expense,
    ),
    Category(
      id: 'category-food',
      name: 'Food',
      icon: 'restaurant',
      color: 0xFFEF6C00,
      type: CategoryType.expense,
    ),
    Category(
      id: 'category-rent',
      name: 'Rent',
      icon: 'home',
      color: 0xFF455A64,
      type: CategoryType.expense,
    ),
    Category(
      id: 'category-salary',
      name: 'Salary',
      icon: 'payments',
      color: 0xFF00897B,
      type: CategoryType.income,
    ),
    Category(
      id: 'category-investment',
      name: 'Investment Income',
      icon: 'trending_up',
      color: 0xFF3949AB,
      type: CategoryType.income,
    ),
    Category(
      id: 'category-vehicle-maintenance',
      name: 'Araç Bakım',
      icon: 'car_repair',
      color: 0xFF546E7A,
      type: CategoryType.expense,
    ),
    Category(
      id: 'category-education',
      name: 'Eğitim',
      icon: 'school',
      color: 0xFF5E35B1,
      type: CategoryType.expense,
    ),
    Category(
      id: 'category-electricity',
      name: 'Elektrik',
      icon: 'electric_bolt',
      color: 0xFFF9A825,
      type: CategoryType.expense,
    ),
    Category(
      id: 'category-natural-gas',
      name: 'Doğalgaz',
      icon: 'local_fire_department',
      color: 0xFFEF6C00,
      type: CategoryType.expense,
    ),
    Category(
      id: 'category-internet',
      name: 'İnternet',
      icon: 'wifi',
      color: 0xFF1976D2,
      type: CategoryType.expense,
    ),
    Category(
      id: 'category-vodafone',
      name: 'Vodafone',
      icon: 'phone_android',
      color: 0xFFE60000,
      type: CategoryType.expense,
    ),
    Category(
      id: 'category-turkcell',
      name: 'Turkcell',
      icon: 'cell_tower',
      color: 0xFF0B74C9,
      type: CategoryType.expense,
    ),
    Category(
      id: 'category-water',
      name: 'Su',
      icon: 'water_drop',
      color: 0xFF0288D1,
      type: CategoryType.expense,
    ),
  ];
}
