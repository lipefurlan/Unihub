/// Faculdade conveniada logada no portal da IES (painel).
class UniversityProfile {
  final int id;
  final String name;
  final String email;
  final List<String> emailDomains;
  final double monthlyFee;
  final double feePerStudent;
  final double subsidyPerStudent;

  const UniversityProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.emailDomains,
    required this.monthlyFee,
    required this.feePerStudent,
    required this.subsidyPerStudent,
  });

  factory UniversityProfile.fromJson(Map<String, dynamic> json) => UniversityProfile(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        emailDomains: (json['email_domains'] as List).cast<String>(),
        monthlyFee: (json['monthly_fee'] as num).toDouble(),
        feePerStudent: (json['fee_per_student'] as num).toDouble(),
        subsidyPerStudent: (json['subsidy_per_student'] as num).toDouble(),
      );
}

/// Fatura do mês: o que a IES paga ao UniHub.
class UniversityInvoice {
  final double monthlyFee;
  final double perStudentFees;
  final double subsidies;
  final double total;

  const UniversityInvoice({
    required this.monthlyFee,
    required this.perStudentFees,
    required this.subsidies,
    required this.total,
  });

  factory UniversityInvoice.fromJson(Map<String, dynamic> json) => UniversityInvoice(
        monthlyFee: (json['monthly_fee'] as num).toDouble(),
        perStudentFees: (json['per_student_fees'] as num).toDouble(),
        subsidies: (json['subsidies'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
      );
}

class UniversityOverview {
  final String referenceMonth;
  final int registeredStudents;
  final int subscribers;
  final int activeUsers;
  final int monthCheckins;
  final double visitsPerActiveUser;
  final UniversityInvoice invoice;
  final List<({String gymName, int checkins})> topGyms;

  const UniversityOverview({
    required this.referenceMonth,
    required this.registeredStudents,
    required this.subscribers,
    required this.activeUsers,
    required this.monthCheckins,
    required this.visitsPerActiveUser,
    required this.invoice,
    required this.topGyms,
  });

  factory UniversityOverview.fromJson(Map<String, dynamic> json) => UniversityOverview(
        referenceMonth: json['reference_month'] as String,
        registeredStudents: json['registered_students'] as int,
        subscribers: json['subscribers'] as int,
        activeUsers: json['active_users'] as int,
        monthCheckins: json['month_checkins'] as int,
        visitsPerActiveUser: (json['visits_per_active_user'] as num).toDouble(),
        invoice: UniversityInvoice.fromJson(json['invoice'] as Map<String, dynamic>),
        topGyms: [
          for (final g in json['top_gyms'] as List)
            (gymName: (g as Map<String, dynamic>)['gym_name'] as String, checkins: g['checkins'] as int),
        ],
      );
}

class UniversityStudentRow {
  final int id;
  final String name;
  final String email;
  final String? subscriptionStatus; // active | paused | null
  final int monthCheckins;
  final DateTime? lastCheckin;

  const UniversityStudentRow({
    required this.id,
    required this.name,
    required this.email,
    this.subscriptionStatus,
    required this.monthCheckins,
    this.lastCheckin,
  });

  factory UniversityStudentRow.fromJson(Map<String, dynamic> json) => UniversityStudentRow(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        subscriptionStatus: json['subscription_status'] as String?,
        monthCheckins: json['month_checkins'] as int,
        lastCheckin: json['last_checkin'] == null ? null : DateTime.parse(json['last_checkin'] as String),
      );
}
