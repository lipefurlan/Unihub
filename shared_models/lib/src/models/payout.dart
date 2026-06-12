import 'checkin.dart';

class Payout {
  final String referenceMonth; // "YYYY-MM"
  final int totalCheckins;
  final double totalAmount;
  final String status; // pending | paid
  final DateTime? paidAt;

  const Payout({
    required this.referenceMonth,
    required this.totalCheckins,
    required this.totalAmount,
    required this.status,
    this.paidAt,
  });

  bool get isPaid => status == 'paid';

  factory Payout.fromJson(Map<String, dynamic> json) => Payout(
        referenceMonth: json['reference_month'] as String,
        totalCheckins: json['total_checkins'] as int,
        totalAmount: (json['total_amount'] as num).toDouble(),
        status: json['status'] as String,
        paidAt: json['paid_at'] == null ? null : DateTime.parse(json['paid_at'] as String),
      );
}

class PayoutDetail extends Payout {
  final List<GymCheckIn> checkins;

  const PayoutDetail({
    required super.referenceMonth,
    required super.totalCheckins,
    required super.totalAmount,
    required super.status,
    super.paidAt,
    required this.checkins,
  });

  factory PayoutDetail.fromJson(Map<String, dynamic> json) => PayoutDetail(
        referenceMonth: json['reference_month'] as String,
        totalCheckins: json['total_checkins'] as int,
        totalAmount: (json['total_amount'] as num).toDouble(),
        status: json['status'] as String,
        paidAt: json['paid_at'] == null ? null : DateTime.parse(json['paid_at'] as String),
        checkins: (json['checkins'] as List)
            .map((c) => GymCheckIn.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}
