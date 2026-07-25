import '../../core/api/api_client.dart';
import 'vehicle_model.dart';

class GarageRepository {
  GarageRepository(this.apiClient);

  final ApiClient apiClient;

  Future<List<Vehicle>> fetchVehicles() async {
    final response = await apiClient.dio.get('/vehicles');
    return (response.data as List)
        .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Vehicle> addVehicle({
    required String plateNumber,
    required String emirateRegistered,
    required String make,
    required String model,
    required int year,
  }) async {
    final response = await apiClient.dio.post('/vehicles', data: {
      'plateNumber': plateNumber,
      'emirateRegistered': emirateRegistered,
      'make': make,
      'model': model,
      'year': year,
    });
    return Vehicle.fromJson(response.data as Map<String, dynamic>);
  }

  Future<HealthScoreBreakdown> fetchHealthScore(String vehicleId) async {
    final response = await apiClient.dio.get('/vehicles/$vehicleId/health-score');
    return HealthScoreBreakdown.fromJson(response.data as Map<String, dynamic>);
  }
}
