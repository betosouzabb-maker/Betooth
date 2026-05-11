class UserEntity {
  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.birthDate,
    required this.phone,
    required this.profilePhotoUrl,
    required this.role,
  });

  final String id;
  final String name;
  final String email;
  final DateTime? birthDate;
  final String? phone;
  final String? profilePhotoUrl;
  final String role;
}