abstract final class CategoryValidator {
  static String validateName(String name) {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw const FormatException('Category name cannot be empty.');
    }
    return normalizedName;
  }
}
