/// Desafio de engajamento: faculdades contra faculdades, ou cursos de uma
/// faculdade entre si. O placar vem calculado da API.
class ChallengeRow {
  final int position;
  final String name; // faculdade ou curso
  final int participants; // assinantes ativos do grupo
  final int checkins;
  final int activeStudents; // com ao menos um treino por semana do desafio
  final double score;

  const ChallengeRow({
    required this.position,
    required this.name,
    required this.participants,
    required this.checkins,
    required this.activeStudents,
    required this.score,
  });

  factory ChallengeRow.fromJson(Map<String, dynamic> json) => ChallengeRow(
        position: json['position'] as int,
        name: json['name'] as String,
        participants: json['participants'] as int,
        checkins: json['checkins'] as int,
        activeStudents: json['active_students'] as int,
        score: (json['score'] as num).toDouble(),
      );
}

/// Placar acumulado no fim de cada semana, para os primeiros colocados.
class ChallengeSeries {
  final String name;
  final List<double> points;

  const ChallengeSeries({required this.name, required this.points});

  factory ChallengeSeries.fromJson(Map<String, dynamic> json) => ChallengeSeries(
        name: json['name'] as String,
        points: (json['points'] as List).map((p) => (p as num).toDouble()).toList(),
      );
}

class Challenge {
  final int id;
  final String title;
  final String? description;
  final String scope; // universities | courses
  final String metric; // checkins_per_student | active_share
  final String metricLabel;
  final int? universityId;
  final String? universityName;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // upcoming | active | ended
  final String publicToken;
  final String createdBy; // admin | ies
  final int groups;
  final int participants;
  final int totalCheckins;
  final String? leader;
  final String? champion;
  // Só no detalhe
  final List<ChallengeRow> ranking;
  final List<DateTime> evolutionLabels;
  final List<ChallengeSeries> evolution;
  // Só na visão do aluno
  final String? myGroup;
  final int myCheckins;

  const Challenge({
    required this.id,
    required this.title,
    this.description,
    required this.scope,
    required this.metric,
    required this.metricLabel,
    this.universityId,
    this.universityName,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.publicToken,
    required this.createdBy,
    required this.groups,
    required this.participants,
    required this.totalCheckins,
    this.leader,
    this.champion,
    this.ranking = const [],
    this.evolutionLabels = const [],
    this.evolution = const [],
    this.myGroup,
    this.myCheckins = 0,
  });

  bool get isActive => status == 'active';
  bool get isEnded => status == 'ended';
  bool get betweenCourses => scope == 'courses';
  bool get sharePercent => metric == 'active_share';

  ChallengeRow? get myRow => ranking.where((r) => r.name == myGroup).firstOrNull;

  /// Pontuação formatada conforme a regra do desafio.
  String formatScore(double score) =>
      sharePercent ? '${score.round()}%' : score.toStringAsFixed(1).replaceAll('.', ',');

  /// Dias até o fim (0 no último dia).
  int get daysLeft {
    final now = DateTime.now();
    return endDate.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  factory Challenge.fromJson(Map<String, dynamic> json) {
    final evolution = json['evolution'] as Map<String, dynamic>?;
    return Challenge(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String,
      description: json['description'] as String?,
      scope: json['scope'] as String,
      metric: json['metric'] as String? ?? 'checkins_per_student',
      metricLabel: json['metric_label'] as String,
      universityId: json['university_id'] as int?,
      universityName: json['university_name'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      status: json['status'] as String,
      publicToken: json['public_token'] as String? ?? '',
      createdBy: json['created_by'] as String? ?? 'admin',
      groups: json['groups'] as int? ?? (json['ranking'] as List? ?? const []).length,
      participants: json['participants'] as int,
      totalCheckins: json['total_checkins'] as int,
      leader: json['leader'] as String?,
      champion: json['champion'] as String?,
      ranking: (json['ranking'] as List? ?? const [])
          .map((r) => ChallengeRow.fromJson(r as Map<String, dynamic>))
          .toList(),
      evolutionLabels: (evolution?['labels'] as List? ?? const [])
          .map((d) => DateTime.parse(d as String))
          .toList(),
      evolution: (evolution?['series'] as List? ?? const [])
          .map((s) => ChallengeSeries.fromJson(s as Map<String, dynamic>))
          .toList(),
      myGroup: json['my_group'] as String?,
      myCheckins: json['my_checkins'] as int? ?? 0,
    );
  }
}
