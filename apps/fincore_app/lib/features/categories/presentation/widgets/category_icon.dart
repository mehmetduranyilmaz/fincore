import 'package:flutter/material.dart';

abstract final class CategoryIcons {
  static const Map<String, IconData> values = {
    'shopping_cart': Icons.shopping_cart_outlined,
    'directions_car': Icons.directions_car_outlined,
    'subscriptions': Icons.subscriptions_outlined,
    'movie': Icons.movie_outlined,
    'bolt': Icons.bolt_outlined,
    'restaurant': Icons.restaurant_outlined,
    'home': Icons.home_outlined,
    'payments': Icons.payments_outlined,
    'trending_up': Icons.trending_up,
    'car_repair': Icons.car_repair_outlined,
    'school': Icons.school_outlined,
    'electric_bolt': Icons.electric_bolt_outlined,
    'local_fire_department': Icons.local_fire_department_outlined,
    'wifi': Icons.wifi_outlined,
    'phone_android': Icons.phone_android_outlined,
    'cell_tower': Icons.cell_tower_outlined,
    'water_drop': Icons.water_drop_outlined,
  };

  static IconData resolve(String key) {
    return values[key] ?? Icons.category_outlined;
  }
}

final class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    required this.icon,
    required this.color,
    this.size = 24,
    super.key,
  });

  final String icon;
  final int color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(CategoryIcons.resolve(icon), color: Color(color), size: size);
  }
}
