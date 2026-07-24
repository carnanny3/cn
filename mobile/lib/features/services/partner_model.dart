class PartnerResult {
  PartnerResult({
    required this.id,
    required this.businessName,
    required this.ratingAvg,
    required this.price,
    this.distanceKm,
    this.durationEstimateMinutes,
  });

  final String id;
  final String businessName;
  final double ratingAvg;
  final double price;
  final double? distanceKm;
  final int? durationEstimateMinutes;

  factory PartnerResult.fromJson(Map<String, dynamic> json) => PartnerResult(
        id: json['id'] as String,
        businessName: json['businessName'] as String? ?? 'Verified Partner',
        ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0,
        price: (json['price'] as num?)?.toDouble() ?? 0,
        distanceKm: (json['distanceKm'] as num?)?.toDouble(),
        durationEstimateMinutes: json['durationEstimateMinutes'] as int?,
      );
}
