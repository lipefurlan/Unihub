import 'gym.dart';

/// Check-in na visão do estudante (histórico do app).
class CheckIn {
  final int id;
  final Gym gym;
  final DateTime timestamp;
  final int planTierAtCheckin;

  const CheckIn({
    required this.id,
    required this.gym,
    required this.timestamp,
    required this.planTierAtCheckin,
  });

  factory CheckIn.fromJson(Map<String, dynamic> json) => CheckIn(
        id: json['id'] as int,
        gym: Gym.fromJson(json['gym'] as Map<String, dynamic>),
        timestamp: DateTime.parse(json['timestamp'] as String),
        planTierAtCheckin: json['plan_tier_at_checkin'] as int,
      );
}

/// Check-in na visão da academia (painel): inclui aluno e valor de repasse.
class GymCheckIn {
  final int id;
  final DateTime timestamp;
  final String studentName;
  final String studentUniversity;
  final int planTierAtCheckin;
  final double payoutAmountRecorded;

  const GymCheckIn({
    required this.id,
    required this.timestamp,
    required this.studentName,
    required this.studentUniversity,
    required this.planTierAtCheckin,
    required this.payoutAmountRecorded,
  });

  factory GymCheckIn.fromJson(Map<String, dynamic> json) => GymCheckIn(
        id: json['id'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
        studentName: json['student_name'] as String,
        studentUniversity: json['student_university'] as String,
        planTierAtCheckin: json['plan_tier_at_checkin'] as int,
        payoutAmountRecorded: (json['payout_amount_recorded'] as num).toDouble(),
      );
}
