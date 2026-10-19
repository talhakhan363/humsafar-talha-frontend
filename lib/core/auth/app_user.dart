/// Mirrors the `user` object every auth endpoint returns
/// (`docs/api/auth_contract.md`). `guardianRole` is null for Dependents.
class AppUser {
  const AppUser({
    required this.userId,
    required this.email,
    required this.phone,
    required this.fullName,
    required this.role,
    required this.guardianRole,
  });

  final String userId;
  final String email;
  final String phone;
  final String fullName;
  final String role; // "guardian" | "dependent"
  final String? guardianRole; // "primary" | "secondary" | null

  bool get isGuardian => role == 'guardian';
  bool get isPrimary => guardianRole == 'primary';

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        userId: json['user_id'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String,
        fullName: json['full_name'] as String,
        role: json['role'] as String,
        guardianRole: json['guardian_role'] as String?,
      );
}
