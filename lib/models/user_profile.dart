class UserProfile {
  final String id;
  final String email;
  final String? role;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final String? department;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int syncStatus;

  UserProfile({
    required this.id,
    required this.email,
    this.role,
    this.fullName,
    this.phone,
    this.avatarUrl,
    this.department,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'role': role,
        'full_name': fullName,
        'phone': phone,
        'avatar_url': avatarUrl,
        'department': department,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'sync_status': syncStatus,
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        id: map['id'] as String,
        email: map['email'] as String,
        role: map['role'] as String?,
        fullName: map['full_name'] as String?,
        phone: map['phone'] as String?,
        avatarUrl: map['avatar_url'] as String?,
        department: map['department'] as String?,
        createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
        updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
        syncStatus: map['sync_status'] as int? ?? 0,
      );

  bool get isAdmin => role == 'admin';
  bool get canEdit => role != 'readonly';
}
