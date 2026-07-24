class InspectionReport {
  InspectionReport({
    required this.overallScore,
    required this.overallStatus,
    required this.categoryScores,
    required this.criticalDefectCount,
    required this.minorDefectCount,
    required this.estimatedRepairCost,
    required this.aiSummary,
    required this.aiRecommendation,
    required this.disclaimer,
  });

  final double overallScore;
  final String overallStatus;
  final Map<String, double> categoryScores;
  final int criticalDefectCount;
  final int minorDefectCount;
  final double estimatedRepairCost;
  final String aiSummary;
  final String aiRecommendation;
  final String disclaimer;

  factory InspectionReport.fromJson(Map<String, dynamic> json) => InspectionReport(
        overallScore: (json['overallScore'] as num).toDouble(),
        overallStatus: json['overallStatus'] as String,
        categoryScores: (json['categoryScores'] as Map).map(
          (key, value) => MapEntry(key as String, (value as num).toDouble()),
        ),
        criticalDefectCount: json['criticalDefectCount'] as int,
        minorDefectCount: json['minorDefectCount'] as int,
        estimatedRepairCost: (json['estimatedRepairCost'] as num).toDouble(),
        aiSummary: json['aiSummary'] as String? ?? '',
        aiRecommendation: json['aiRecommendation'] as String? ?? 'proceed_with_caution',
        disclaimer: json['disclaimer'] as String? ?? '',
      );

  String get recommendationLabel {
    switch (aiRecommendation) {
      case 'buy':
        return 'Buy';
      case 'buy_after_negotiation':
        return 'Buy after negotiation';
      case 'do_not_buy':
        return 'Do not buy';
      case 'proceed_with_caution':
      default:
        return 'Proceed with caution';
    }
  }
}
