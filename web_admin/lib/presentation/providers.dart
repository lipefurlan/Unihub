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
