import 'package:shared_models/shared_models.dart';

import 'token_storage.dart';

/// Sessão do painel: academia (gym), operação UniHub (admin) ou faculdade (ies).
class PanelSession {
  final String role; // gym | admin | ies
  final Gym? gym;
  final AdminProfile? admin;
  final UniversityProfile? university;

  const PanelSession.gym(Gym this.gym) : role = 'gym', admin = null, university = null;

  const PanelSession.admin(AdminProfile this.admin)
    : role = 'admin',
      gym = null,
      university = null;

  const PanelSession.university(UniversityProfile this.university)
    : role = 'ies',
      gym = null,
      admin = null;

  bool get isAdmin => role == 'admin';
  bool get isUniversity => role == 'ies';

  /// Prefixo das rotas de cada área (cada role só navega na sua)
  String get areaPrefix => isAdmin ? '/admin' : (isUniversity ? '/ies' : '');

  String get home => isAdmin ? '/admin/overview' : (isUniversity ? '/ies/overview' : '/dashboard');

  String get displayName =>
      isAdmin ? admin!.name : (isUniversity ? university!.name : gym!.name);
}

class PanelAuthRepository {
  PanelAuthRepository(this._api, this._storage);

  final ApiClient _api;
  final TokenStorage _storage;

  /// Restaura a sessão salva e busca o perfil correspondente ao role.
  Future<PanelSession?> restore() async {
    final stored = await _storage.read();
    if (stored == null) return null;
    final (token, role) = stored;
    _api.token = token;
    return _fetchProfile(role);
  }

  Future<PanelSession> login(String email, String password) async =>
      _startSession(await _api.login(email, password));

  Future<PanelSession> loginWithGoogle(String credential) async =>
      _startSession(await _api.loginWithGoogle(credential, allowSignup: false));

  Future<PanelSession> _startSession(AuthResult result) async {
    if (result.role == 'student') {
      throw const ApiException('Esta conta é de estudante. Use o app UniHub.');
    }
    _api.token = result.accessToken;
    await _storage.write(result.accessToken, result.role);
    return _fetchProfile(result.role);
  }

  Future<PanelSession> _fetchProfile(String role) async {
    if (role == 'admin') {
      return PanelSession.admin(await _api.getAdminMe());
    }
    if (role == 'ies') {
      return PanelSession.university(await _api.getUniversityMe());
    }
    return PanelSession.gym(await _api.getMyGym());
  }

  Future<PanelSession> refresh(PanelSession current) =>
      _fetchProfile(current.role);

  Future<void> logout() async {
    _api.token = null;
    await _storage.clear();
  }
}
