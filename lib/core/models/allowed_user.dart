/// Represents a single row from allowed_admins or allowed_riders.
class AllowedUserEntry {
  const AllowedUserEntry({
    required this.id,
    required this.phoneNumber,
    required this.name,
    required this.createdAt,
    this.isSuperAdmin = false,
  });

  final String id;
  final String phoneNumber;
  final String name;
  final DateTime createdAt;
  /// Only meaningful for admin entries. Always false for rider entries.
  final bool isSuperAdmin;

  factory AllowedUserEntry.fromJson(Map<String, dynamic> json) {
    return AllowedUserEntry(
      id: json['id'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      name: json['name'] as String? ?? '',
      isSuperAdmin: json['isSuperAdmin'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
