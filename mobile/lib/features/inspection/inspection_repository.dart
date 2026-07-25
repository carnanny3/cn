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
    final response = await apiClient.dio.get('/inspections/$inspectionId/report');
    return InspectionReport.fromJson(response.data as Map<String, dynamic>);
  }
}
