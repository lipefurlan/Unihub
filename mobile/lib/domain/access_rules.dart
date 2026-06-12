import 'package:shared_models/shared_models.dart';

/// Regras de acesso espelhadas do backend (a validação oficial é da API;
/// aqui servem para feedback imediato na UI).

/// O plano do estudante cobre a academia?
bool planCoversGym(Student? student, Gym gym) =>
    (student?.planTier ?? 0) >= gym.minPlanTier;

/// Posição mockada do estudante (campus da Unicamp) — o POC não usa GPS real.
const campusLatitude = -22.8170;
const campusLongitude = -47.0698;

double gymDistanceKm(Gym gym) =>
    distanceInKm(campusLatitude, campusLongitude, gym.latitude, gym.longitude);

/// Ordena academias da mais próxima para a mais distante.
List<Gym> sortByDistance(List<Gym> gyms) {
  final sorted = [...gyms];
  sorted.sort((a, b) => gymDistanceKm(a).compareTo(gymDistanceKm(b)));
  return sorted;
}
