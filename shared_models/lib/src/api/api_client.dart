import 'package:dio/dio.dart';

import '../models/admin.dart';
import '../models/challenge.dart';
import '../models/checkin.dart';
import '../models/dashboard.dart';
import '../models/gym.dart';
import '../models/payout.dart';
import '../models/plan.dart';
import '../models/student.dart';
import '../models/subscription.dart';
import '../models/university.dart';
import 'api_exception.dart';

class AuthResult {
  final String accessToken;
  final String role; // student | gym | admin | ies

  const AuthResult({required this.accessToken, required this.role});
}

/// Cliente HTTP único da API UniHub, compartilhado entre app e painel.
///
/// A URL base pode ser sobrescrita em build com:
///   flutter run --dart-define=UNIHUB_API=http://10.0.2.2:8000
class ApiClient {
  ApiClient({String? baseUrl})
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ??
                const String.fromEnvironment('UNIHUB_API', defaultValue: 'http://127.0.0.1:8000'),
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 15),
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) options.headers['Authorization'] = 'Bearer $_token';
          handler.next(options);
        },
        onError: (error, handler) {
          // Sessão expirou no meio do uso (JWT de 24h): avisa o app para
          // voltar ao login em vez de deixar as telas em erro
          final isAuthRoute = error.requestOptions.path.startsWith('/auth/');
          if (error.response?.statusCode == 401 && _token != null && !isAuthRoute) {
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  String? _token;

  set token(String? value) => _token = value;

  /// Chamado quando a API responde 401 a uma requisição autenticada.
  void Function()? onUnauthorized;
  bool get hasToken => _token != null;

  Future<T> _run<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ------------------------------------------------------------------ auth

  Future<AuthResult> login(String email, String password) => _run(() async {
        final res = await _dio.post('/auth/login', data: {'email': email, 'password': password});
        return AuthResult(
          accessToken: res.data['access_token'] as String,
          role: res.data['role'] as String,
        );
      });

  Future<AuthResult> registerStudent({
    required String name,
    required String email,
    required String password,
    String? course,
  }) =>
      _run(() async {
        // A universidade vem do domínio do e-mail (IES conveniada)
        final res = await _dio.post('/auth/register/student', data: {
          'name': name,
          'email': email,
          'password': password,
          'course': ?course,
        });
        return AuthResult(
          accessToken: res.data['access_token'] as String,
          role: res.data['role'] as String,
        );
      });

  /// Login com Google: [credential] é o ID token do botão do Google. No
  /// primeiro acesso, cria a conta de estudante (e-mail de IES conveniada),
  /// a menos que [allowSignup] seja false (painel).
  Future<AuthResult> loginWithGoogle(String credential, {bool allowSignup = true}) =>
      _run(() async {
        final res = await _dio.post('/auth/google', data: {
          'credential': credential,
          'allow_signup': allowSignup,
        });
        return AuthResult(
          accessToken: res.data['access_token'] as String,
          role: res.data['role'] as String,
        );
      });

  /// Pede o link de redefinição por e-mail; devolve a mensagem da API.
  Future<String> forgotPassword(String email) => _run(() async {
        final res = await _dio.post('/auth/forgot-password', data: {'email': email});
        return res.data['detail'] as String;
      });

  Future<String> resetPassword(String token, String newPassword) => _run(() async {
        final res = await _dio.post('/auth/reset-password', data: {
          'token': token,
          'new_password': newPassword,
        });
        return res.data['detail'] as String;
      });

  // ------------------------------------------------------------- estudante

  Future<Student> getMyProfile() => _run(() async {
        final res = await _dio.get('/students/me');
        return Student.fromJson(res.data as Map<String, dynamic>);
      });

  Future<Student> updateMyProfile({
    int? weeklyGoal,
    String? homeCity,
    bool clearHomeCity = false,
    String? course,
  }) =>
      _run(() async {
        final res = await _dio.put('/students/me', data: {
          'weekly_goal': ?weeklyGoal,
          if (homeCity != null || clearHomeCity) 'home_city': homeCity,
          'course': ?course,
        });
        return Student.fromJson(res.data as Map<String, dynamic>);
      });

  Future<StudentStats> getMyStats() => _run(() async {
        final res = await _dio.get('/students/me/stats');
        return StudentStats.fromJson(res.data as Map<String, dynamic>);
      });

  Future<List<Gym>> getMyFavorites() => _run(() async {
        final res = await _dio.get('/students/me/favorites');
        return (res.data as List).map((g) => Gym.fromJson(g as Map<String, dynamic>)).toList();
      });

  Future<void> setFavorite(int gymId, bool favorite) => _run(() async {
        if (favorite) {
          await _dio.put('/students/me/favorites/$gymId');
        } else {
          await _dio.delete('/students/me/favorites/$gymId');
        }
      });

  Future<List<String>> getGymCities() => _run(() async {
        final res = await _dio.get('/gyms/cities');
        return (res.data as List).cast<String>();
      });

  Future<GymBusyHours> getGymBusyHours(int gymId) => _run(() async {
        final res = await _dio.get('/gyms/$gymId/busy-hours');
        return GymBusyHours.fromJson(res.data as Map<String, dynamic>);
      });

  Future<Achievements> getMyAchievements() => _run(() async {
        final res = await _dio.get('/students/me/achievements');
        return Achievements.fromJson(res.data as Map<String, dynamic>);
      });

  /// Desafios ativos de que o aluno participa, com o grupo dele e quanto já somou.
  Future<List<Challenge>> getMyChallenges() => _run(() async {
        final res = await _dio.get('/students/me/challenges');
        return (res.data as List).map((c) => Challenge.fromJson(c as Map<String, dynamic>)).toList();
      });

  /// Faculdades conveniadas (id e nome), para o painel montar desafios.
  Future<List<({int id, String name})>> getUniversities() => _run(() async {
        final res = await _dio.get('/universities');
        return [
          for (final u in res.data as List) (id: u['id'] as int, name: u['name'] as String),
        ];
      });

  /// Cursos aceitos no cadastro (agrupam os desafios entre cursos).
  Future<List<String>> getCourses() => _run(() async {
        final res = await _dio.get('/universities/courses');
        return (res.data as List).cast<String>();
      });

  Future<CheckIn> rateCheckin(int checkinId, int stars) => _run(() async {
        final res = await _dio.put('/checkins/$checkinId/rating', data: {'stars': stars});
        return CheckIn.fromJson(res.data as Map<String, dynamic>);
      });

  Future<List<TrendingGym>> getTrendingGyms() => _run(() async {
        final res = await _dio.get('/gyms/trending');
        return (res.data as List)
            .map((g) => TrendingGym.fromJson(g as Map<String, dynamic>))
            .toList();
      });

  Future<List<Plan>> getPlans() => _run(() async {
        final res = await _dio.get('/plans');
        return (res.data as List).map((p) => Plan.fromJson(p as Map<String, dynamic>)).toList();
      });

  Future<List<Gym>> getGyms({String? modality, String? search, String? city}) => _run(() async {
        final res = await _dio.get('/gyms', queryParameters: {
          'modality': ?modality,
          'city': ?city,
          if (search != null && search.isNotEmpty) 'search': search,
        });
        return (res.data as List).map((g) => Gym.fromJson(g as Map<String, dynamic>)).toList();
      });

  Future<Gym> getGym(int id) => _run(() async {
        final res = await _dio.get('/gyms/$id');
        return Gym.fromJson(res.data as Map<String, dynamic>);
      });

  Future<List<CheckIn>> getMyCheckins() => _run(() async {
        final res = await _dio.get('/students/me/checkins');
        return (res.data as List).map((c) => CheckIn.fromJson(c as Map<String, dynamic>)).toList();
      });

  Future<CheckIn> createCheckin(int gymId) => _run(() async {
        final res = await _dio.post('/checkins', data: {'gym_id': gymId});
        return CheckIn.fromJson(res.data as Map<String, dynamic>);
      });

  Future<Subscription> createSubscription(int planId) => _run(() async {
        final res = await _dio.post('/subscriptions', data: {'plan_id': planId});
        return Subscription.fromJson(res.data as Map<String, dynamic>);
      });

  Future<Subscription> updateSubscription(int id, {int? planId, String? status}) => _run(() async {
        final res = await _dio.put('/subscriptions/$id', data: {
          'plan_id': ?planId,
          'status': ?status,
        });
        return Subscription.fromJson(res.data as Map<String, dynamic>);
      });

  // -------------------------------------------------------------- academia

  Future<Gym> getMyGym() => _run(() async {
        final res = await _dio.get('/gyms/me');
        return Gym.fromJson(res.data as Map<String, dynamic>);
      });

  Future<Gym> updateGym(int id, Map<String, dynamic> data) => _run(() async {
        final res = await _dio.put('/gyms/$id', data: data);
        return Gym.fromJson(res.data as Map<String, dynamic>);
      });

  Future<GymDashboard> getGymDashboard() => _run(() async {
        final res = await _dio.get('/gyms/me/dashboard');
        return GymDashboard.fromJson(res.data as Map<String, dynamic>);
      });

  Future<List<GymCheckIn>> getGymCheckins({int limit = 50}) => _run(() async {
        final res = await _dio.get('/gyms/me/checkins', queryParameters: {'limit': limit});
        return (res.data as List).map((c) => GymCheckIn.fromJson(c as Map<String, dynamic>)).toList();
      });

  Future<List<GymStudentRow>> getGymStudents() => _run(() async {
        final res = await _dio.get('/gyms/me/students');
        return (res.data as List)
            .map((s) => GymStudentRow.fromJson(s as Map<String, dynamic>))
            .toList();
      });

  /// Recepção valida o código de entrada mostrado pelo aluno.
  Future<EntryValidation> validateEntryCode(String code) => _run(() async {
        final res = await _dio.post('/gyms/me/checkins/validate', data: {'code': code});
        return EntryValidation.fromJson(res.data as Map<String, dynamic>);
      });

  Future<List<Payout>> getGymPayouts() => _run(() async {
        final res = await _dio.get('/gyms/me/payouts');
        return (res.data as List).map((p) => Payout.fromJson(p as Map<String, dynamic>)).toList();
      });

  Future<PayoutDetail> getGymPayoutDetail(String referenceMonth) => _run(() async {
        final res = await _dio.get('/gyms/me/payouts/$referenceMonth');
        return PayoutDetail.fromJson(res.data as Map<String, dynamic>);
      });

  /// Baixa o extrato CSV do mês e devolve o conteúdo como texto.
  Future<String> downloadPayoutCsv(String referenceMonth) => _run(() async {
        final res = await _dio.get(
          '/gyms/me/payouts/$referenceMonth/export',
          options: Options(responseType: ResponseType.plain),
        );
        return res.data as String;
      });

  // ------------------------------------------------- operação (admin)

  Future<AdminProfile> getAdminMe() => _run(() async {
        final res = await _dio.get('/admin/me');
        return AdminProfile.fromJson(res.data as Map<String, dynamic>);
      });

  Future<PlatformOverview> getAdminOverview() => _run(() async {
        final res = await _dio.get('/admin/overview');
        return PlatformOverview.fromJson(res.data as Map<String, dynamic>);
      });

  Future<List<AdminGym>> getAdminGyms() => _run(() async {
        final res = await _dio.get('/admin/gyms');
        return (res.data as List).map((g) => AdminGym.fromJson(g as Map<String, dynamic>)).toList();
      });

  Future<AdminGym> createGym(Map<String, dynamic> data) => _run(() async {
        final res = await _dio.post('/admin/gyms', data: data);
        return AdminGym.fromJson(res.data as Map<String, dynamic>);
      });

  Future<AdminGym> updateGymAsAdmin(int id, Map<String, dynamic> data) => _run(() async {
        final res = await _dio.put('/admin/gyms/$id', data: data);
        return AdminGym.fromJson(res.data as Map<String, dynamic>);
      });

  /// Sobe a foto da academia (bytes do arquivo escolhido no painel).
  Future<AdminGym> uploadGymPhoto(int id, List<int> bytes, String filename) => _run(() async {
        final form = FormData.fromMap({
          'photo': MultipartFile.fromBytes(bytes, filename: filename),
        });
        final res = await _dio.post('/admin/gyms/$id/photo', data: form);
        return AdminGym.fromJson(res.data as Map<String, dynamic>);
      });

  Future<List<AdminPayoutRow>> getAdminPayouts({String? month}) => _run(() async {
        final res = await _dio.get('/admin/payouts', queryParameters: {'month': ?month});
        return (res.data as List)
            .map((p) => AdminPayoutRow.fromJson(p as Map<String, dynamic>))
            .toList();
      });

  Future<AdminPayoutRow> markPayoutPaid(int gymId, String referenceMonth) => _run(() async {
        final res = await _dio.post('/admin/payouts/$gymId/$referenceMonth/mark-paid');
        return AdminPayoutRow.fromJson(res.data as Map<String, dynamic>);
      });

  /// Gera senha temporária (suporte manual); a API devolve a senha uma vez.
  Future<String> generateTemporaryPassword({int? studentId, int? gymId}) => _run(() async {
        final path = studentId != null
            ? '/admin/students/$studentId/temporary-password'
            : '/admin/gyms/$gymId/temporary-password';
        final res = await _dio.post(path);
        return res.data['temporary_password'] as String;
      });

  // ------------------------------------------------ portal da IES

  Future<UniversityProfile> getUniversityMe() => _run(() async {
        final res = await _dio.get('/ies/me');
        return UniversityProfile.fromJson(res.data as Map<String, dynamic>);
      });

  Future<UniversityOverview> getUniversityOverview() => _run(() async {
        final res = await _dio.get('/ies/me/overview');
        return UniversityOverview.fromJson(res.data as Map<String, dynamic>);
      });

  Future<List<UniversityStudentRow>> getUniversityStudents() => _run(() async {
        final res = await _dio.get('/ies/me/students');
        return (res.data as List)
            .map((s) => UniversityStudentRow.fromJson(s as Map<String, dynamic>))
            .toList();
      });

  Future<List<AdminStudentRow>> getAdminStudents() => _run(() async {
        final res = await _dio.get('/admin/students');
        return (res.data as List)
            .map((s) => AdminStudentRow.fromJson(s as Map<String, dynamic>))
            .toList();
      });

  // ------------------------------------------------ desafios (painel)
  // [asUniversity]: a faculdade logada vê os dela; senão, a operação vê todos.

  String _challengesPath(bool asUniversity) => asUniversity ? '/ies/me/challenges' : '/admin/challenges';

  Future<List<Challenge>> getChallenges({bool asUniversity = false}) => _run(() async {
        final res = await _dio.get(_challengesPath(asUniversity));
        return (res.data as List).map((c) => Challenge.fromJson(c as Map<String, dynamic>)).toList();
      });

  Future<Challenge> getChallengeDetail(int id, {bool asUniversity = false}) => _run(() async {
        final res = await _dio.get('${_challengesPath(asUniversity)}/$id');
        return Challenge.fromJson(res.data as Map<String, dynamic>);
      });

  Future<Challenge> createChallenge(Map<String, dynamic> data, {bool asUniversity = false}) =>
      _run(() async {
        final res = await _dio.post(_challengesPath(asUniversity), data: data);
        return Challenge.fromJson(res.data as Map<String, dynamic>);
      });

  Future<void> deleteChallenge(int id, {bool asUniversity = false}) => _run(() async {
        await _dio.delete('${_challengesPath(asUniversity)}/$id');
      });

  /// Placar público do desafio (sem login): TV da faculdade, grupo da turma.
  Future<Challenge> getScoreboard(String token) => _run(() async {
        final res = await _dio.get('/public/scoreboard/$token');
        return Challenge.fromJson(res.data as Map<String, dynamic>);
      });
}
