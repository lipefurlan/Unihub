import 'package:shared_models/shared_models.dart';

/// Regras de acesso espelhadas do backend (a validação oficial é da API;
/// aqui servem para feedback imediato na UI).

/// O plano do estudante cobre a academia?
bool planCoversGym(Student? student, Gym gym) =>
    (student?.planTier ?? 0) >= gym.minPlanTier;

/// Campus da Unicamp: posição usada quando o navegador não libera a localização.
const campusLatitude = -22.8170;
const campusLongitude = -47.0698;

/// Posição do aluno usada nas distâncias. Começa no campus e passa para a
/// localização real quando o aluno permite (ver userLocationProvider).
class UserLocation {
  const UserLocation(this.latitude, this.longitude, {required this.isReal});

  static const campus = UserLocation(campusLatitude, campusLongitude, isReal: false);

  /// Última posição conhecida; as telas observam userLocationProvider para redesenhar.
  static UserLocation current = campus;

  final double latitude;
  final double longitude;
  final bool isReal;
}

double gymDistanceKm(Gym gym) => distanceInKm(
      UserLocation.current.latitude,
      UserLocation.current.longitude,
      gym.latitude,
      gym.longitude,
    );

/// Ordena academias da mais próxima para a mais distante.
List<Gym> sortByDistance(List<Gym> gyms) {
  final sorted = [...gyms];
  sorted.sort((a, b) => gymDistanceKm(a).compareTo(gymDistanceKm(b)));
  return sorted;
}
