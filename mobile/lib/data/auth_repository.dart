import 'package:shared_models/shared_models.dart';

import 'token_storage.dart';

/// Orquestra autenticação: API + persistência do token.
class AuthRepository {
  AuthRepository(this._api, this._storage);

  final ApiClient _api;
  final TokenStorage _storage;

  /// Restaura a sessão salva; retorna o token ou null.
  Future<String?> restoreToken() async {
    final token = await _storage.read();
    if (token != null) _api.token = token;
    return token;
  }

  Future<Student> login(String email, String password) async {
    final result = await _api.login(email, password);
    if (result.role != 'student') {
      throw const ApiException('Esta conta é de academia. Use o painel web da academia.');
    }
    _api.token = result.accessToken;
    await _storage.write(result.accessToken);
    return _api.getMyProfile();
  }

  Future<Student> register({
    required String name,
    required String email,
    required String password,
    required String university,
  }) async {
    final result = await _api.registerStudent(
      name: name,
      email: email,
      password: password,
      university: university,
    );
    _api.token = result.accessToken;
    await _storage.write(result.accessToken);
    return _api.getMyProfile();
  }

  Future<Student> fetchProfile() => _api.getMyProfile();

  Future<void> logout() async {
    _api.token = null;
    await _storage.clear();
  }
}
