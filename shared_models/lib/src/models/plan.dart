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
  });

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
