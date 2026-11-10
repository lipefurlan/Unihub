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
  final double subscriptionRevenue; // o que os alunos pagam (já com subsídio)
  final double iesRevenue; // taxa fixa + (taxa + subsídio) por aluno, das IES
  final int monthCheckins;
  final int monthUnpaidCheckins; // visitas acima do teto mensal, sem repasse
  final double monthPayoutTotal;
  final double estimatedMargin;
  final int activeGyms;
  final int activeUniversities;
  final List<TopGym> topGyms;

  const PlatformOverview({
    required this.activeStudents,
    required this.subscriptionRevenue,
    required this.iesRevenue,
    required this.monthCheckins,
    required this.monthUnpaidCheckins,
    required this.monthPayoutTotal,
    required this.estimatedMargin,
    required this.activeGyms,
    required this.activeUniversities,
    required this.topGyms,
  });

  factory PlatformOverview.fromJson(Map<String, dynamic> json) => PlatformOverview(
        activeStudents: json['active_students'] as int,
        subscriptionRevenue: (json['subscription_revenue'] as num).toDouble(),
        iesRevenue: (json['ies_revenue'] as num? ?? 0).toDouble(),
        monthCheckins: json['month_checkins'] as int,
        monthUnpaidCheckins: json['month_unpaid_checkins'] as int? ?? 0,
        monthPayoutTotal: (json['month_payout_total'] as num).toDouble(),
        estimatedMargin: (json['estimated_margin'] as num).toDouble(),
        activeGyms: json['active_gyms'] as int,
        activeUniversities: json['active_universities'] as int? ?? 0,
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
  final String? institutionalEmail;
  final bool verified; // confirmou os dois e-mails

  const AdminStudentRow({
    required this.id,
    required this.name,
    required this.email,
    required this.university,
    this.planName,
    this.subscriptionStatus,
    required this.totalCheckins,
    this.institutionalEmail,
    this.verified = true,
  });

  factory AdminStudentRow.fromJson(Map<String, dynamic> json) => AdminStudentRow(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        university: json['university'] as String,
        planName: json['plan_name'] as String?,
        subscriptionStatus: json['subscription_status'] as String?,
        totalCheckins: json['total_checkins'] as int,
        institutionalEmail: json['institutional_email'] as String?,
        verified: json['verified'] as bool? ?? true,
      );
}


/// Faculdade na tela "Faculdades" da operação, com a lista de alunos da IES.
class AdminUniversity {
  final int id;
  final String name;
  final List<String> emailDomains;
  final bool isActive;
  final int students;
  final int verifiedStudents;
  final int rosterSize; // 0 = valida só pelo domínio + código
  final DateTime? rosterImportedAt;
  final int studentsInRoster;
  final int studentsOutsideRoster;

  const AdminUniversity({
    required this.id,
    required this.name,
    required this.emailDomains,
    required this.isActive,
    required this.students,
    required this.verifiedStudents,
    required this.rosterSize,
    this.rosterImportedAt,
    required this.studentsInRoster,
    required this.studentsOutsideRoster,
  });

  bool get hasRoster => rosterSize > 0;

  factory AdminUniversity.fromJson(Map<String, dynamic> json) => AdminUniversity(
        id: json['id'] as int,
        name: json['name'] as String,
        emailDomains: (json['email_domains'] as List).cast<String>(),
        isActive: json['is_active'] as bool,
        students: json['students'] as int,
        verifiedStudents: json['verified_students'] as int,
        rosterSize: json['roster_size'] as int,
        rosterImportedAt: json['roster_imported_at'] == null
            ? null
            : DateTime.parse(json['roster_imported_at'] as String),
        studentsInRoster: json['students_in_roster'] as int,
        studentsOutsideRoster: json['students_outside_roster'] as int,
      );
}

class RosterEntry {
  final String email;
  final String? name;
  final String? ra;
  final bool registered; // já criou conta no UniHub

  const RosterEntry({required this.email, this.name, this.ra, required this.registered});

  factory RosterEntry.fromJson(Map<String, dynamic> json) => RosterEntry(
        email: json['email'] as String,
        name: json['name'] as String?,
        ra: json['ra'] as String?,
        registered: json['registered'] as bool,
      );
}

/// Resumo da importação do CSV.
class RosterImportResult {
  final int totalRows;
  final int imported;
  final int duplicates;
  final int invalid;
  final int wrongDomain;
  final int rosterSize;
  final List<String> errors;

  const RosterImportResult({
    required this.totalRows,
    required this.imported,
    required this.duplicates,
    required this.invalid,
    required this.wrongDomain,
    required this.rosterSize,
    required this.errors,
  });

  factory RosterImportResult.fromJson(Map<String, dynamic> json) => RosterImportResult(
        totalRows: json['total_rows'] as int,
        imported: json['imported'] as int,
        duplicates: json['duplicates'] as int,
        invalid: json['invalid'] as int,
        wrongDomain: json['wrong_domain'] as int,
        rosterSize: json['roster_size'] as int,
        errors: (json['errors'] as List).cast<String>(),
      );
}
