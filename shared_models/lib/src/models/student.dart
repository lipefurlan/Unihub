import 'plan.dart';
import 'subscription.dart';

class Student {
  final int id;
  final String name;
  final String email;
  final String university;
  final String? photoUrl;
  final String status;
  final Subscription? subscription;
  final double universitySubsidy; // subsídio mensal da IES conveniada

  const Student({
    required this.id,
    required this.name,
    required this.email,
    required this.university,
    this.photoUrl,
    required this.status,
    this.subscription,
    this.universitySubsidy = 0,
  });

  /// Tier do plano vigente (0 = sem assinatura).
  int get planTier => subscription?.plan.tier ?? 0;

  /// Quanto o aluno paga pelo plano: preço cheio menos o subsídio da IES.
  double priceFor(Plan plan) =>
      (plan.monthlyPrice - universitySubsidy).clamp(0, double.infinity).toDouble();

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        university: json['university'] as String,
        photoUrl: json['photo_url'] as String?,
        status: json['status'] as String,
        subscription: json['subscription'] == null
            ? null
            : Subscription.fromJson(json['subscription'] as Map<String, dynamic>),
        universitySubsidy: (json['university_subsidy'] as num? ?? 0).toDouble(),
      );
}
