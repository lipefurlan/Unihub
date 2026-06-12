class DailyCount {
  final String date; // "YYYY-MM-DD"
  final int count;

  const DailyCount({required this.date, required this.count});

  factory DailyCount.fromJson(Map<String, dynamic> json) =>
      DailyCount(date: json['date'] as String, count: json['count'] as int);
}

class HourRangeCount {
  final String label; // ex.: "06h–09h"
  final int count;

  const HourRangeCount({required this.label, required this.count});

  factory HourRangeCount.fromJson(Map<String, dynamic> json) =>
      HourRangeCount(label: json['label'] as String, count: json['count'] as int);
}

class GymDashboard {
  final int monthCheckins;
  final int uniqueStudents;
  final double estimatedRevenue;
  final int prevMonthCheckins;
  final double prevMonthRevenue;
  final List<DailyCount> checkinsByDay;
  final List<HourRangeCount> checkinsByHourRange;

  const GymDashboard({
    required this.monthCheckins,
    required this.uniqueStudents,
    required this.estimatedRevenue,
    required this.prevMonthCheckins,
    required this.prevMonthRevenue,
    required this.checkinsByDay,
    required this.checkinsByHourRange,
  });

  factory GymDashboard.fromJson(Map<String, dynamic> json) => GymDashboard(
        monthCheckins: json['month_checkins'] as int,
        uniqueStudents: json['unique_students'] as int,
        estimatedRevenue: (json['estimated_revenue'] as num).toDouble(),
        prevMonthCheckins: json['prev_month_checkins'] as int,
        prevMonthRevenue: (json['prev_month_revenue'] as num).toDouble(),
        checkinsByDay: (json['checkins_by_day'] as List)
            .map((d) => DailyCount.fromJson(d as Map<String, dynamic>))
            .toList(),
        checkinsByHourRange: (json['checkins_by_hour_range'] as List)
            .map((h) => HourRangeCount.fromJson(h as Map<String, dynamic>))
            .toList(),
      );
}

class GymStudentRow {
  final int studentId;
  final String name;
  final String university;
  final String? planName;
  final int totalCheckins;
  final DateTime lastCheckin;

  const GymStudentRow({
    required this.studentId,
    required this.name,
    required this.university,
    this.planName,
    required this.totalCheckins,
    required this.lastCheckin,
  });

  factory GymStudentRow.fromJson(Map<String, dynamic> json) => GymStudentRow(
        studentId: json['student_id'] as int,
        name: json['name'] as String,
        university: json['university'] as String,
        planName: json['plan_name'] as String?,
        totalCheckins: json['total_checkins'] as int,
        lastCheckin: DateTime.parse(json['last_checkin'] as String),
      );
}
