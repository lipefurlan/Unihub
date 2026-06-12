class Gym {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> modalities;
  final int minPlanTier;
  final int capacity;
  final String openingHours;
  final String? photoUrl;

  /// Presente apenas na visão da própria academia (painel).
  final String? email;
  final double? checkinPayoutAmount;

  const Gym({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.modalities,
    required this.minPlanTier,
    required this.capacity,
    required this.openingHours,
    this.photoUrl,
    this.email,
    this.checkinPayoutAmount,
  });

  factory Gym.fromJson(Map<String, dynamic> json) => Gym(
        id: json['id'] as int,
        name: json['name'] as String,
        address: json['address'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        modalities: (json['modalities'] as List).cast<String>(),
        minPlanTier: json['min_plan_tier'] as int,
        capacity: json['capacity'] as int,
        openingHours: json['opening_hours'] as String,
        photoUrl: json['photo_url'] as String?,
        email: json['email'] as String?,
        checkinPayoutAmount: (json['checkin_payout_amount'] as num?)?.toDouble(),
      );
}
