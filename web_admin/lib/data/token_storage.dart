import 'package:shared_preferences/shared_preferences.dart';

/// Persistência local da sessão do painel (localStorage no web).
class TokenStorage {
  static const _tokenKey = 'unihub_panel_token';
  static const _roleKey = 'unihub_panel_role';

  Future<(String, String)?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final role = prefs.getString(_roleKey);
    if (token == null || role == null) return null;
    return (token, role);
  }

  Future<void> write(String token, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_roleKey, role);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
  }
}
