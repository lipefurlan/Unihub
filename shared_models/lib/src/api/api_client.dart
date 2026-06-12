import 'package:dio/dio.dart';

import '../models/admin.dart';
import '../models/checkin.dart';
import '../models/dashboard.dart';
import '../models/gym.dart';
import '../models/payout.dart';
import '../models/plan.dart';
import '../models/student.dart';
import '../models/subscription.dart';
import 'api_exception.dart';

class AuthResult {
  final String accessToken;
  final String role; // student | gym

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
      ),
    );
  }

  final Dio _dio;
  String? _token;

  set token(String? value) => _token = value;
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
    required String university,
  }) =>
      _run(() async {
        final res = await _dio.post('/auth/register/student', data: {
          'name': name,
          'email': email,
          'password': password,
          'university': university,
        });
        return AuthResult(
          accessToken: res.data['access_token'] as String,
          role: res.data['role'] as String,
        );
      });

  // ------------------------------------------------------------- estudante

  Future<Student> getMyProfile() => _run(() async {
        final res = await _dio.get('/students/me');
        return Student.fromJson(res.data as Map<String, dynamic>);
      });

  Future<List<Plan>> getPlans() => _run(() async {
        final res = await _dio.get('/plans');
        return (res.data as List).map((p) => Plan.fromJson(p as Map<String, dynamic>)).toList();
      });

  Future<List<Gym>> getGyms({String? modality, String? search}) => _run(() async {
        final res = await _dio.get('/gyms', queryParameters: {
          'modality': ?modality,
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

  Future<List<AdminStudentRow>> getAdminStudents() => _run(() async {
        final res = await _dio.get('/admin/students');
        return (res.data as List)
            .map((s) => AdminStudentRow.fromJson(s as Map<String, dynamic>))
            .toList();
      });
}
