class Vehicle {
  Vehicle({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.plateNumber,
    this.primaryPhotoUrl,
    this.healthScore,
  });

  final String id;
  final String make;
  final String model;
  final int year;
  final String plateNumber;
  final String? primaryPhotoUrl;
  final int? healthScore;

  String get label => '$year $make $model';

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'] as String,
        make: json['make'] as String,
        model: json['model'] as String,
        year: json['year'] as int,
        plateNumber: json['plateNumber'] as String? ?? '',
        primaryPhotoUrl: json['primaryPhotoUrl'] as String?,
        healthScore: json['healthScore'] as int?,
      );
}

class HealthScoreBreakdown {
  HealthScoreBreakdown({
    required this.overall,
    required this.categories,
    required this.recommendations,
  });

  final int overall;
  final Map<String, int> categories;
  final List<String> recommendations;

  factory HealthScoreBreakdown.fromJson(Map<String, dynamic> json) => HealthScoreBreakdown(
        overall: json['overall'] as int,
        categories: Map<String, int>.from(json['categories'] as Map),
        recommendations: List<String>.from(json['recommendations'] as List),
      );
}
