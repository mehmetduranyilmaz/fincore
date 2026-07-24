final class User {
  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.isActive,
  });

  final String id;
  final String fullName;
  final String email;
  final bool isActive;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is User &&
            id == other.id &&
            fullName == other.fullName &&
            email == other.email &&
            isActive == other.isActive;
  }

  @override
  int get hashCode => Object.hash(id, fullName, email, isActive);
}
