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
  });

  final String dependentId;
  final String email;
  final String phone;
  final String myRole; // "primary" | "secondary"
  final String kycStatus; // "pending" | "verified" | "failed"
  final bool accountActive;

  bool get isPrimary => myRole == 'primary';

  factory DependentSummary.fromJson(Map<String, dynamic> json) => DependentSummary(
        dependentId: json['dependent_id'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String,
        myRole: json['my_role'] as String,
        kycStatus: json['kyc_status'] as String,
        accountActive: json['account_active'] as bool,
      );
}
