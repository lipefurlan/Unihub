import 'subscription.dart';

class Student {
  final int id;
  final String name;
  final String email;
  final String university;
  final String? photoUrl;
  final String status;
  final Subscription? subscription;

  const Student({
    required this.id,
    required this.name,
    required this.email,
    required this.university,
    this.photoUrl,
    required this.status,
    this.subscription,
  });

  /// Tier do plano vigente (0 = sem assinatura).
  int get planTier => subscription?.plan.tier ?? 0;

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
      );
}
