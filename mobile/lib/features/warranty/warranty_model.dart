class WarrantyPlan {
  WarrantyPlan({
    required this.id,
    required this.name,
    required this.coverageSummary,
    this.exclusions,
    required this.price,
    required this.providerName,
    this.eligible,
  });

  final String id;
  final String name;
  final String coverageSummary;
  final String? exclusions;
  final double price;
  final String providerName;
  final bool? eligible;

  factory WarrantyPlan.fromJson(Map<String, dynamic> json) => WarrantyPlan(
        id: json['id'] as String,
        name: json['name'] as String,
        coverageSummary: json['coverageSummary'] as String,
        exclusions: json['exclusions'] as String?,
        price: (json['price'] as num).toDouble(),
        providerName: (json['providerPartner'] as Map<String, dynamic>?)?['businessName'] as String? ?? 'Partner',
        eligible: json['eligible'] as bool?,
      );
}

class WarrantyClaim {
  WarrantyClaim({
    required this.id,
    required this.description,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
  });

  final String id;
  final String description;
  final String status;
  final String? rejectionReason;
  final DateTime createdAt;

  factory WarrantyClaim.fromJson(Map<String, dynamic> json) => WarrantyClaim(
        id: json['id'] as String,
        description: json['description'] as String,
        status: json['status'] as String,
        rejectionReason: json['rejectionReason'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class WarrantyPolicy {
  WarrantyPolicy({
    required this.id,
    required this.policyNumber,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.planName,
    required this.claims,
  });

  final String id;
  final String policyNumber;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final String planName;
  final List<WarrantyClaim> claims;

  factory WarrantyPolicy.fromJson(Map<String, dynamic> json) => WarrantyPolicy(
        id: json['id'] as String,
        policyNumber: json['policyNumber'] as String,
        status: json['status'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        planName: (json['plan'] as Map<String, dynamic>?)?['name'] as String? ?? 'Warranty Plan',
        claims: (json['claims'] as List? ?? []).map((e) => WarrantyClaim.fromJson(e as Map<String, dynamic>)).toList(),
      );
}
