class Employee {
  final String id;
  final String? userId;
  final String? employeeNumber;
  final String fullName;
  final String? email;
  final String? phone;
  final String? department;
  final String? jobTitle;
  final double? salary;
  final double? hourlyRate;
  final DateTime? startDate;
  final String? bankDetails;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int syncStatus;
  final DateTime? deletedAt;

  Employee({
    required this.id,
    this.userId,
    this.employeeNumber,
    required this.fullName,
    this.email,
    this.phone,
    this.department,
    this.jobTitle,
    this.salary,
    this.hourlyRate,
    this.startDate,
    this.bankDetails,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = 0,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'employee_number': employeeNumber,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'department': department,
        'job_title': jobTitle,
        'salary': salary,
        'hourly_rate': hourlyRate,
        'start_date': startDate?.toIso8601String(),
        'bank_details': bankDetails,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'sync_status': syncStatus,
        'deleted_at': deletedAt?.toIso8601String(),
      };

  factory Employee.fromMap(Map<String, dynamic> map) => Employee(
        id: map['id'] as String,
        userId: map['user_id'] as String?,
        employeeNumber: map['employee_number'] as String?,
        fullName: map['full_name'] as String,
        email: map['email'] as String?,
        phone: map['phone'] as String?,
        department: map['department'] as String?,
        jobTitle: map['job_title'] as String?,
        salary: (map['salary'] as num?)?.toDouble(),
        hourlyRate: (map['hourly_rate'] as num?)?.toDouble(),
        startDate: map['start_date'] != null ? DateTime.parse(map['start_date'] as String) : null,
        bankDetails: map['bank_details'] as String?,
        isActive: map['is_active'] == 1,
        createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
        updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
        syncStatus: map['sync_status'] as int? ?? 0,
        deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at'] as String) : null,
      );
}
