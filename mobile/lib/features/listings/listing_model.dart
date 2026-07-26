class VehicleListingItem {
  VehicleListingItem({
    required this.id,
    required this.sellerType,
    required this.make,
    required this.model,
    required this.year,
    this.mileageKm,
    required this.askingPrice,
    required this.status,
    this.inspectionId,
    this.photoUrls = const [],
    required this.createdAt,
  });

  final String id;
  final String sellerType;
  final String make;
  final String model;
  final int year;
  final int? mileageKm;
  final double askingPrice;
  final String status;
  final String? inspectionId;
  final List<String> photoUrls;
  final DateTime createdAt;

  String get title => '$year $make $model';

  factory VehicleListingItem.fromJson(Map<String, dynamic> json) {
    final photos = json['photos'] as Map<String, dynamic>?;
    final urls = (photos?['urls'] as List? ?? []).map((e) => e as String).toList();
    return VehicleListingItem(
      id: json['id'] as String,
      sellerType: json['sellerType'] as String,
      make: json['make'] as String,
      model: json['model'] as String,
      year: json['year'] as int,
      mileageKm: json['mileageKm'] as int?,
      askingPrice: (json['askingPrice'] as num).toDouble(),
      status: json['status'] as String,
      inspectionId: json['inspectionId'] as String?,
      photoUrls: urls,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
