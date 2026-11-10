class Plan {
  final int id;
  final String name;
  final double monthlyPrice;
  final int tier;
  final String color; // hex vindo da API, ex.: "#FF5A1F"
  final List<String> includedCategories;
  final String benefitsDescription;
  final bool hasRunningCoach;
  final bool isActive;

  /// true: todas as academias (respeitando o tier mínimo de cada uma);
  /// false: só as academias de [gymIds].
  final bool allGyms;
  final List<int> gymIds;
  final int? maxCheckinsPerMonth;
  final int? maxCheckinsPerDay;
  final String? allowedFrom; // "HH:MM"
  final String? allowedUntil;
  final String restrictionsNote;

  const Plan({
    required this.id,
    required this.name,
    required this.monthlyPrice,
    required this.tier,
    required this.color,
    required this.includedCategories,
    required this.benefitsDescription,
    required this.hasRunningCoach,
    this.isActive = true,
    this.allGyms = true,
    this.gymIds = const [],
    this.maxCheckinsPerMonth,
    this.maxCheckinsPerDay,
    this.allowedFrom,
    this.allowedUntil,
    this.restrictionsNote = '',
  });

  /// O plano cobre a academia? (a regra oficial é a da API)
  bool coversGym(int gymId, int gymMinTier) => allGyms ? tier >= gymMinTier : gymIds.contains(gymId);

  /// Restrições em frases curtas, para mostrar no app e no painel.
  List<String> get restrictionLines => [
        if (allowedFrom != null && allowedUntil != null) 'Das $allowedFrom às $allowedUntil',
        if (maxCheckinsPerDay != null) '$maxCheckinsPerDay check-in${maxCheckinsPerDay == 1 ? '' : 's'} por dia',
        if (maxCheckinsPerMonth != null) '$maxCheckinsPerMonth check-ins por mês',
        if (restrictionsNote.isNotEmpty) restrictionsNote,
      ];

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
        id: json['id'] as int,
        name: json['name'] as String,
        monthlyPrice: (json['monthly_price'] as num).toDouble(),
        tier: json['tier'] as int,
        color: json['color'] as String,
        includedCategories: (json['included_categories'] as List).cast<String>(),
        benefitsDescription: json['benefits_description'] as String,
        hasRunningCoach: json['has_running_coach'] as bool,
        isActive: json['is_active'] as bool? ?? true,
        allGyms: json['all_gyms'] as bool? ?? true,
        gymIds: ((json['gym_ids'] as List?) ?? const []).cast<int>(),
        maxCheckinsPerMonth: json['max_checkins_per_month'] as int?,
        maxCheckinsPerDay: json['max_checkins_per_day'] as int?,
        allowedFrom: json['allowed_from'] as String?,
        allowedUntil: json['allowed_until'] as String?,
        restrictionsNote: json['restrictions_note'] as String? ?? '',
      );
}

/// Plano visto pela operação UniHub, com o número de assinantes ativos.
class AdminPlan {
  final Plan plan;
  final int activeSubscribers;

  const AdminPlan({required this.plan, required this.activeSubscribers});

  factory AdminPlan.fromJson(Map<String, dynamic> json) => AdminPlan(
        plan: Plan.fromJson(json),
        activeSubscribers: json['active_subscribers'] as int? ?? 0,
      );
}
