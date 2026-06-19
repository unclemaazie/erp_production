class Vehicle {
  final String id;
  final String registration;
  final String? make;
  final String? model;
  final int? year;
  final String? vin;
  final String status;
  final String? assignedDriverId;
  final double currentOdometer;
  final String? fuelType;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int syncStatus;
  final DateTime? deletedAt;

  Vehicle({
    required this.id,
    required this.registration,
    this.make,
    this.model,
    this.year,
    this.vin,
    this.status = 'active',
    this.assignedDriverId,
    this.currentOdometer = 0,
    this.fuelType,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = 0,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'registration': registration,
        'make': make,
        'model': model,
        'year': year,
        'vin': vin,
        'status': status,
        'assigned_driver_id': assignedDriverId,
        'current_odometer': currentOdometer,
        'fuel_type': fuelType,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'sync_status': syncStatus,
        'deleted_at': deletedAt?.toIso8601String(),
      };

  factory Vehicle.fromMap(Map<String, dynamic> map) => Vehicle(
        id: map['id'] as String,
        registration: map['registration'] as String,
        make: map['make'] as String?,
        model: map['model'] as String?,
        year: map['year'] as int?,
        vin: map['vin'] as String?,
        status: map['status'] as String? ?? 'active',
        assignedDriverId: map['assigned_driver_id'] as String?,
        currentOdometer: (map['current_odometer'] as num?)?.toDouble() ?? 0,
        fuelType: map['fuel_type'] as String?,
        createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
        updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
        syncStatus: map['sync_status'] as int? ?? 0,
        deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at'] as String) : null,
      );
}

class FleetTrip {
  final String id;
  final String vehicleId;
  final String? driverId;
  final String? startLocation;
  final String? endLocation;
  final double? startOdometer;
  final double? endOdometer;
  final double? distance;
  final String? purpose;
  final double fuelCost;
  final DateTime? tripDate;
  final DateTime? createdAt;
  final int syncStatus;

  FleetTrip({
    required this.id,
    required this.vehicleId,
    this.driverId,
    this.startLocation,
    this.endLocation,
    this.startOdometer,
    this.endOdometer,
    this.distance,
    this.purpose,
    this.fuelCost = 0,
    this.tripDate,
    this.createdAt,
    this.syncStatus = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'vehicle_id': vehicleId,
        'driver_id': driverId,
        'start_location': startLocation,
        'end_location': endLocation,
        'start_odometer': startOdometer,
        'end_odometer': endOdometer,
        'distance': distance,
        'purpose': purpose,
        'fuel_cost': fuelCost,
        'trip_date': tripDate?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
        'sync_status': syncStatus,
      };

  factory FleetTrip.fromMap(Map<String, dynamic> map) => FleetTrip(
        id: map['id'] as String,
        vehicleId: map['vehicle_id'] as String,
        driverId: map['driver_id'] as String?,
        startLocation: map['start_location'] as String?,
        endLocation: map['end_location'] as String?,
        startOdometer: (map['start_odometer'] as num?)?.toDouble(),
        endOdometer: (map['end_odometer'] as num?)?.toDouble(),
        distance: (map['distance'] as num?)?.toDouble(),
        purpose: map['purpose'] as String?,
        fuelCost: (map['fuel_cost'] as num?)?.toDouble() ?? 0,
        tripDate: map['trip_date'] != null ? DateTime.parse(map['trip_date'] as String) : null,
        createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
        syncStatus: map['sync_status'] as int? ?? 0,
      );
}
