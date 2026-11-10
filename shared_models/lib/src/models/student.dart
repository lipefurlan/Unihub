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
  final int weeklyGoal; // meta de treinos por semana
  final String? homeCity; // cidade natal (fins de semana e férias)
  final String? course; // disputa os desafios entre cursos da faculdade

  const Student({
    required this.id,
    required this.name,
    required this.email,
    required this.university,
    this.photoUrl,
    required this.status,
    this.subscription,
    this.universitySubsidy = 0,
    this.weeklyGoal = 3,
    this.homeCity,
    this.course,
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
        weeklyGoal: json['weekly_goal'] as int? ?? 3,
        homeCity: json['home_city'] as String?,
        course: json['course'] as String?,
      );
}


/// Uma semana (segunda a domingo) no histórico da meta.
class WeekStat {
  final DateTime weekStart;
  final int checkins;
  final bool goalMet;

  const WeekStat({required this.weekStart, required this.checkins, required this.goalMet});

  factory WeekStat.fromJson(Map<String, dynamic> json) => WeekStat(
        weekStart: DateTime.parse(json['week_start'] as String),
        checkins: json['checkins'] as int,
        goalMet: json['goal_met'] as bool,
      );
}

/// Meta semanal, sequência de semanas e resumo do mês do aluno.
class StudentStats {
  final int weeklyGoal;
  final int weekCheckins;
  final int streakWeeks;
  final List<WeekStat> lastWeeks;
  final int monthCheckins;
  final int monthGyms;
  final String? monthTopGym;

  const StudentStats({
    required this.weeklyGoal,
    required this.weekCheckins,
    required this.streakWeeks,
    required this.lastWeeks,
    required this.monthCheckins,
    required this.monthGyms,
    this.monthTopGym,
  });

  factory StudentStats.fromJson(Map<String, dynamic> json) => StudentStats(
        weeklyGoal: json['weekly_goal'] as int,
        weekCheckins: json['week_checkins'] as int,
        streakWeeks: json['streak_weeks'] as int,
        lastWeeks: (json['last_weeks'] as List)
            .map((w) => WeekStat.fromJson(w as Map<String, dynamic>))
            .toList(),
        monthCheckins: json['month_checkins'] as int,
        monthGyms: json['month_gyms'] as int,
        monthTopGym: json['month_top_gym'] as String?,
      );
}


/// Selo de conquista (conquistado ou em progresso).
class AchievementBadge {
  final String code;
  final String title;
  final String description;
  final int target;
  final int progress;
  final bool achieved;

  const AchievementBadge({
    required this.code,
    required this.title,
    required this.description,
    required this.target,
    required this.progress,
    required this.achieved,
  });

  factory AchievementBadge.fromJson(Map<String, dynamic> json) => AchievementBadge(
        code: json['code'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        target: json['target'] as int,
        progress: json['progress'] as int,
        achieved: json['achieved'] as bool,
      );
}

class Achievements {
  final int totalCheckins;
  final int gymsVisited;
  final int currentStreak;
  final int bestStreak;
  final List<AchievementBadge> badges;

  const Achievements({
    required this.totalCheckins,
    required this.gymsVisited,
    required this.currentStreak,
    required this.bestStreak,
    required this.badges,
  });

  factory Achievements.fromJson(Map<String, dynamic> json) => Achievements(
        totalCheckins: json['total_checkins'] as int,
        gymsVisited: json['gyms_visited'] as int,
        currentStreak: json['current_streak'] as int,
        bestStreak: json['best_streak'] as int,
        badges: (json['badges'] as List)
            .map((b) => AchievementBadge.fromJson(b as Map<String, dynamic>))
            .toList(),
      );
}
