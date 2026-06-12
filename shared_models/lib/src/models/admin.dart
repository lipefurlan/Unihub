/// Modelos do backoffice (operação UniHub).
library;

class AdminProfile {
  final int id;
  final String name;
  final String email;

  const AdminProfile({required this.id, required this.name, required this.email});

  factory AdminProfile.fromJson(Map<String, dynamic> json) => AdminProfile(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
      );
}

class TopGym {
  final String gymName;
  final int checkins;

  const TopGym({required this.gymName, required this.checkins});

  factory TopGym.fromJson(Map<String, dynamic> json) =>
      TopGym(gymName: json['gym_name'] as String, checkins: json['checkins'] as int);
}

class PlatformOverview {
  final int activeStudents;
  final double subscriptionRevenue;
  final int monthCheckins;
  final double monthPayoutTotal;
  final double estimatedMargin;
  final int activeGyms;
  final List<TopGym> topGyms;

  const PlatformOverview({
    required this.activeStudents,
    required this.subscriptionRevenue,
    required this.monthCheckins,
    required this.monthPayoutTotal,
    required this.estimatedMargin,
    required this.activeGyms,
    required this.topGyms,
  });

  factory PlatformOverview.fromJson(Map<String, dynamic> json) => PlatformOverview(
        activeStudents: json['active_students'] as int,
        subscriptionRevenue: (json['subscription_revenue'] as num).toDouble(),
        monthCheckins: json['month_checkins'] as int,
        monthPayoutTotal: (json['month_payout_total'] as num).toDouble(),
        estimatedMargin: (json['estimated_margin'] as num).toDouble(),
        activeGyms: json['active_gyms'] as int,
        topGyms: (json['top_gyms'] as List)
            .map((t) => TopGym.fromJson(t as Map<String, dynamic>))
            .toList(),
      );
}

class AdminGym {
  final int id;
  final String name;
  final String email;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> modalities;
  final int minPlanTier;
  final double checkinPayoutAmount;
  final int capacity;
  final String openingHours;
  final String? photoUrl;
  final bool isActive;
  final int monthCheckins;
  final double monthAmount;

  const AdminGym({
    required this.id,
    required this.name,
    required this.email,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.modalities,
    required this.minPlanTier,
    required this.checkinPayoutAmount,
    required this.capacity,
    required this.openingHours,
    this.photoUrl,
    required this.isActive,
    required this.monthCheckins,
    required this.monthAmount,
  });

  factory AdminGym.fromJson(Map<String, dynamic> json) => AdminGym(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        address: json['address'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        modalities: (json['modalities'] as List).cast<String>(),
        minPlanTier: json['min_plan_tier'] as int,
        checkinPayoutAmount: (json['checkin_payout_amount'] as num).toDouble(),
        capacity: json['capacity'] as int,
        openingHours: json['opening_hours'] as String,
        photoUrl: json['photo_url'] as String?,
        isActive: json['is_active'] as bool,
        monthCheckins: json['month_checkins'] as int,
        monthAmount: (json['month_amount'] as num).toDouble(),
      );
}

class AdminPayoutRow {
  final int gymId;
  final String gymName;
  final String referenceMonth;
  final int totalCheckins;
  final double totalAmount;
  final String status; // pending | paid
  final DateTime? paidAt;

  const AdminPayoutRow({
    required this.gymId,
    required this.gymName,
    required this.referenceMonth,
    required this.totalCheckins,
    required this.totalAmount,
    required this.status,
    this.paidAt,
  });

  bool get isPaid => status == 'paid';

  factory AdminPayoutRow.fromJson(Map<String, dynamic> json) => AdminPayoutRow(
        gymId: json['gym_id'] as int,
        gymName: json['gym_name'] as String,
        referenceMonth: json['reference_month'] as String,
        totalCheckins: json['total_checkins'] as int,
        totalAmount: (json['total_amount'] as num).toDouble(),
        status: json['status'] as String,
        paidAt: json['paid_at'] == null ? null : DateTime.parse(json['paid_at'] as String),
      );
}

class AdminStudentRow {
  final int id;
  final String name;
  final String email;
  final String university;
  final String? planName;
  final String? subscriptionStatus;
  final int totalCheckins;

  const AdminStudentRow({
    required this.id,
    required this.name,
    required this.email,
    required this.university,
    this.planName,
    this.subscriptionStatus,
    required this.totalCheckins,
  });

  factory AdminStudentRow.fromJson(Map<String, dynamic> json) => AdminStudentRow(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        university: json['university'] as String,
        planName: json['plan_name'] as String?,
        subscriptionStatus: json['subscription_status'] as String?,
        totalCheckins: json['total_checkins'] as int,
      );
}
