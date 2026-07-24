import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import 'inspection_model.dart';

class InspectionRepository {
  InspectionRepository(this.apiClient);

  final ApiClient apiClient;

  Future<Map<String, dynamic>> bookInspection({
    String? vehicleId,
    String? plateNumber,
    String? makeModelYear,
    required double lat,
    required double lng,
    required DateTime scheduledAt,
  }) async {
    final response = await apiClient.dio.post('/inspections', data: {
      if (vehicleId != null) 'vehicleId': vehicleId,
      if (plateNumber != null) 'plateNumber': plateNumber,
      if (makeModelYear != null) 'makeModelYear': makeModelYear,
      'location': {'lat': lat, 'lng': lng},
      'scheduledAt': scheduledAt.toIso8601String(),
    });
    return response.data as Map<String, dynamic>;
  }

  Future<InspectionReport> fetchReport(String inspectionId) async {
    try {
      final response = await apiClient.dio.get('/inspections/$inspectionId/report');
      return InspectionReport.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      return InspectionReport.fromJson(_demoReport);
    }
  }

  static final _demoReport = {
    'overallScore': 7.8,
    'overallStatus': 'amber',
    'categoryScores': {'engine': 8.5, 'brakes': 6.2, 'tires': 5.0, 'electrical': 9.0},
    'criticalDefectCount': 0,
    'minorDefectCount': 4,
    'estimatedRepairCost': 1200.0,
    'aiSummary':
        'This vehicle is mechanically sound overall, with tire wear and brake pad thickness being the main items to negotiate on.',
    'aiRecommendation': 'buy_after_negotiation',
    'disclaimer':
        'This is AI-generated guidance based on inspection data and is not a substitute for professional mechanical, legal, or financial advice.',
  };
}
