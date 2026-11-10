import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

import '../data/panel_auth_repository.dart';
import '../data/token_storage.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final authRepositoryProvider = Provider<PanelAuthRepository>(
  (ref) => PanelAuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  ),
);

/// Sessão do painel: academia ou admin (null = deslogado).
class PanelSessionNotifier extends AsyncNotifier<PanelSession?> {
  @override
  Future<PanelSession?> build() async {
    final repo = ref.watch(authRepositoryProvider);
    ref.read(apiClientProvider).onUnauthorized = () {
      if (state.value != null) logout();
    };
    try {
      return await repo.restore();
    } on ApiException {
      // Token expirado/inválido: volta para o login
      await repo.logout();
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    final session = await ref
        .read(authRepositoryProvider)
        .login(email, password);
    state = AsyncData(session);
  }

  Future<void> loginWithGoogle(String credential) async {
    final session = await ref
        .read(authRepositoryProvider)
        .loginWithGoogle(credential);
    state = AsyncData(session);
  }

  Future<void> refreshProfile() async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(await ref.read(authRepositoryProvider).refresh(current));
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}

final sessionProvider =
    AsyncNotifierProvider<PanelSessionNotifier, PanelSession?>(
      PanelSessionNotifier.new,
    );

// --------------------------------------------------------- dados (academia)

final dashboardProvider = FutureProvider<GymDashboard>(
  (ref) => ref.watch(apiClientProvider).getGymDashboard(),
);

final gymCheckinsProvider = FutureProvider<List<GymCheckIn>>(
  (ref) => ref.watch(apiClientProvider).getGymCheckins(limit: 100),
);

final gymStudentsProvider = FutureProvider<List<GymStudentRow>>(
  (ref) => ref.watch(apiClientProvider).getGymStudents(),
);

final payoutsProvider = FutureProvider<List<Payout>>(
  (ref) => ref.watch(apiClientProvider).getGymPayouts(),
);

final payoutDetailProvider = FutureProvider.family<PayoutDetail, String>(
  (ref, month) => ref.watch(apiClientProvider).getGymPayoutDetail(month),
);

// ----------------------------------------------------------- dados (admin)

final adminOverviewProvider = FutureProvider<PlatformOverview>(
  (ref) => ref.watch(apiClientProvider).getAdminOverview(),
);

final adminGymsProvider = FutureProvider<List<AdminGym>>(
  (ref) => ref.watch(apiClientProvider).getAdminGyms(),
);

final adminPayoutsProvider =
    FutureProvider.family<List<AdminPayoutRow>, String>(
      (ref, month) =>
          ref.watch(apiClientProvider).getAdminPayouts(month: month),
    );

final adminStudentsProvider = FutureProvider<List<AdminStudentRow>>(
  (ref) => ref.watch(apiClientProvider).getAdminStudents(),
);

// ------------------------------------------------------ dados (faculdade)

final iesOverviewProvider = FutureProvider<UniversityOverview>(
  (ref) => ref.watch(apiClientProvider).getUniversityOverview(),
);

final iesStudentsProvider = FutureProvider<List<UniversityStudentRow>>(
  (ref) => ref.watch(apiClientProvider).getUniversityStudents(),
);

// ------------------------------------------------------------- desafios
// Operação vê todos; a faculdade, os entre faculdades e os dos seus cursos.

bool _asUniversity(Ref ref) => ref.watch(sessionProvider).value?.isUniversity == true;

final challengesProvider = FutureProvider<List<Challenge>>(
  (ref) => ref.watch(apiClientProvider).getChallenges(asUniversity: _asUniversity(ref)),
);

final challengeDetailProvider = FutureProvider.family<Challenge, int>(
  (ref, id) => ref.watch(apiClientProvider).getChallengeDetail(id, asUniversity: _asUniversity(ref)),
);

final universitiesProvider = FutureProvider<List<({int id, String name})>>(
  (ref) => ref.watch(apiClientProvider).getUniversities(),
);

final scoreboardProvider = FutureProvider.family<Challenge, String>(
  (ref, token) => ref.watch(apiClientProvider).getScoreboard(token),
);
