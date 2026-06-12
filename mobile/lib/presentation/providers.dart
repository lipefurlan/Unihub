import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

import '../data/auth_repository.dart';
import '../data/token_storage.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider), ref.watch(tokenStorageProvider)),
);

/// Estado de autenticação: o perfil do estudante logado (null = deslogado).
class AuthNotifier extends AsyncNotifier<Student?> {
  @override
  Future<Student?> build() async {
    final repo = ref.watch(authRepositoryProvider);
    final token = await repo.restoreToken();
    if (token == null) return null;
    try {
      return await repo.fetchProfile();
    } on ApiException {
      // Token expirado/inválido: volta para o login
      await repo.logout();
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    final repo = ref.read(authRepositoryProvider);
    final profile = await repo.login(email, password);
    state = AsyncData(profile);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String university,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    final profile = await repo.register(
      name: name,
      email: email,
      password: password,
      university: university,
    );
    state = AsyncData(profile);
  }

  Future<void> refreshProfile() async {
    final repo = ref.read(authRepositoryProvider);
    state = AsyncData(await repo.fetchProfile());
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, Student?>(AuthNotifier.new);

// ----------------------------------------------------------------- catálogo

final plansProvider = FutureProvider<List<Plan>>(
  (ref) => ref.watch(apiClientProvider).getPlans(),
);

final gymsProvider = FutureProvider<List<Gym>>(
  (ref) => ref.watch(apiClientProvider).getGyms(),
);

final gymDetailProvider = FutureProvider.family<Gym, int>(
  (ref, id) => ref.watch(apiClientProvider).getGym(id),
);

final myCheckinsProvider = FutureProvider<List<CheckIn>>(
  (ref) => ref.watch(apiClientProvider).getMyCheckins(),
);
