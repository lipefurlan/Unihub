import 'package:shared_models/shared_models.dart';

import 'token_storage.dart';

/// Sessão do painel: academia (role gym) ou operação UniHub (role admin).
class PanelSession {
  final String role; // gym | admin
  final Gym? gym;
  final AdminProfile? admin;

  const PanelSession.gym(Gym this.gym)
      : role = 'gym',
        admin = null;

  const PanelSession.admin(AdminProfile this.admin)
      : role = 'admin',
        gym = null;

  bool get isAdmin => role == 'admin';

  String get displayName => isAdmin ? admin!.name : gym!.name;
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

  Future<PanelSession> login(String email, String password) async {
    final result = await _api.login(email, password);
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
    return PanelSession.gym(await _api.getMyGym());
  }

  Future<PanelSession> refresh(PanelSession current) => _fetchProfile(current.role);

  Future<void> logout() async {
    _api.token = null;
    await _storage.clear();
  }
}
