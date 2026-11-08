/// One entry from GET /guardians/me/dependents (linkage_contract.md
/// section 2) - the Dependent switcher FR-B4 asks for.
class DependentSummary {
  const DependentSummary({
    required this.dependentId,
    required this.email,
    required this.phone,
    required this.myRole,
    required this.kycStatus,
    required this.accountActive,
    this.fullName = '',
  });

  final String dependentId;
  final String email;
  final String phone;
  final String myRole; // "primary" | "secondary"
  final String kycStatus; // "pending" | "verified" | "failed"
  final bool accountActive;

  /// Bug fix (F-04, ICP-1 Results v1.1 / 3.16 N-07): `full_name` added to
  /// `GET /guardians/me/dependents` (Abdullah, 2026-11-08) — an empty
  /// string when the Dependent never gave a name, per his own note on the
  /// change, not a null, so [displayName] checks `isEmpty`, not null.
  final String fullName;

  bool get isPrimary => myRole == 'primary';

  /// The Dependent's real name once the backend has one, falling back to
  /// the email otherwise — same fallback every call site used before
  /// this field existed, now centralized here instead of repeated per
  /// screen.
  String get displayName => fullName.isEmpty ? email : fullName;

  factory DependentSummary.fromJson(Map<String, dynamic> json) => DependentSummary(
        dependentId: json['dependent_id'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String,
        myRole: json['my_role'] as String,
        kycStatus: json['kyc_status'] as String,
        accountActive: json['account_active'] as bool,
        fullName: json['full_name'] as String? ?? '',
      );
}
