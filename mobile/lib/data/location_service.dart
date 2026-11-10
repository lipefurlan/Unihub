import 'package:geolocator/geolocator.dart';

import '../domain/access_rules.dart';

/// Pede a localização ao navegador/celular. Se o aluno negar, demorar ou o
/// aparelho não tiver GPS, segue com o campus (o app nunca trava por isso).
Future<UserLocation> fetchUserLocation() async {
  try {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return UserLocation.campus;
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 8),
      ),
    );
    return UserLocation(position.latitude, position.longitude, isReal: true);
  } catch (_) {
    return UserLocation.campus;
  }
}
