import 'gym.dart';

/// Check-in na visão do estudante (histórico do app).
class CheckIn {
  final int id;
  final Gym gym;
  final DateTime timestamp;
  final int planTierAtCheckin;

  /// Só na resposta do check-in: código que a recepção valida
  final String? entryCode;
  final bool isPaid;

  const CheckIn({
    required this.id,
    required this.gym,
    required this.timestamp,
    required this.planTierAtCheckin,
    this.entryCode,
    this.isPaid = true,
  });

  factory CheckIn.fromJson(Map<String, dynamic> json) => CheckIn(
        id: json['id'] as int,
        gym: Gym.fromJson(json['gym'] as Map<String, dynamic>),
        timestamp: DateTime.parse(json['timestamp'] as String),
        planTierAtCheckin: json['plan_tier_at_checkin'] as int,
        entryCode: json['entry_code'] as String?,
        isPaid: json['is_paid'] as bool? ?? true,
      );
}

/// Resultado da validação do código de entrada na recepção.
class EntryValidation {
  final int id;
  final String studentName;
  final String studentUniversity;
  final DateTime timestamp;
  final DateTime validatedAt;
  final bool alreadyValidated;

  const EntryValidation({
    required this.id,
    required this.studentName,
    required this.studentUniversity,
    required this.timestamp,
    required this.validatedAt,
    required this.alreadyValidated,
  });

  factory EntryValidation.fromJson(Map<String, dynamic> json) => EntryValidation(
        id: json['id'] as int,
        studentName: json['student_name'] as String,
        studentUniversity: json['student_university'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        validatedAt: DateTime.parse(json['validated_at'] as String),
        alreadyValidated: json['already_validated'] as bool,
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
  final bool isPaid; // false = acima do teto mensal do aluno, sem repasse
  final DateTime? validatedAt; // entrada confirmada na recepção

  const GymCheckIn({
    required this.id,
    required this.timestamp,
    required this.studentName,
    required this.studentUniversity,
    required this.planTierAtCheckin,
    required this.payoutAmountRecorded,
    this.isPaid = true,
    this.validatedAt,
  });

  factory GymCheckIn.fromJson(Map<String, dynamic> json) => GymCheckIn(
        id: json['id'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
        studentName: json['student_name'] as String,
        studentUniversity: json['student_university'] as String,
        planTierAtCheckin: json['plan_tier_at_checkin'] as int,
        payoutAmountRecorded: (json['payout_amount_recorded'] as num).toDouble(),
        isPaid: json['is_paid'] as bool? ?? true,
        validatedAt: json['validated_at'] == null ? null : DateTime.parse(json['validated_at'] as String),
      );
}
