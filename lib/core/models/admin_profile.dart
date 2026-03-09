/// Admin user profile model.
///
/// Populated from auth response (Truecaller or WhatsApp OTP verify).
class AdminProfile {
  final String userId;
  final String phoneNumber;
  final String? firstName;
  final String? lastName;

  const AdminProfile({
    required this.userId,
    required this.phoneNumber,
    this.firstName,
    this.lastName,
  });

  String get displayName {
    final parts = [
      if (firstName?.isNotEmpty == true) firstName!,
      if (lastName?.isNotEmpty == true) lastName!,
    ];
    return parts.isNotEmpty ? parts.join(' ') : phoneNumber;
  }

  String get initials {
    if (firstName?.isNotEmpty == true) {
      final fn = firstName![0].toUpperCase();
      final ln = (lastName?.isNotEmpty == true) ? lastName![0].toUpperCase() : '';
      return '$fn$ln';
    }
    if (phoneNumber.length >= 2) return phoneNumber.substring(0, 2);
    return phoneNumber;
  }

  factory AdminProfile.fromJson(Map<String, dynamic> json) {
    return AdminProfile(
      userId: json['userId']?.toString() ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
    );
  }
}
