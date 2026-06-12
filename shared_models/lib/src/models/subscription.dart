import 'plan.dart';

class Subscription {
  final int id;
  final Plan plan;
  final DateTime startDate;
  final DateTime renewalDate;
  final double amount;
  final String status; // active | paused | canceled

  const Subscription({
    required this.id,
    required this.plan,
    required this.startDate,
    required this.renewalDate,
    required this.amount,
    required this.status,
  });

  bool get isActive => status == 'active';

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
        id: json['id'] as int,
        plan: Plan.fromJson(json['plan'] as Map<String, dynamic>),
        startDate: DateTime.parse(json['start_date'] as String),
        renewalDate: DateTime.parse(json['renewal_date'] as String),
        amount: (json['amount'] as num).toDouble(),
        status: json['status'] as String,
      );
}
