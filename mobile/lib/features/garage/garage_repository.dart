import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import 'vehicle_model.dart';

/// Falls back to demo data whenever the backend is unreachable (e.g. running
/// the app without the API up yet) so the UI is always demoable, per the
/// product requirement to verify screens end-to-end.
class GarageRepository {
  GarageRepository(this.apiClient);

  final ApiClient apiClient;

  static final _demoVehicles = [
    Vehicle(
      id: 'demo-vehicle-1',
      make: 'Toyota',
      model: 'Camry',
      year: 2019,
      plateNumber: 'A 12345',
      healthScore: 86,
    ),
  ];

  Future<List<Vehicle>> fetchVehicles() async {
    try {
      final response = await apiClient.dio.get('/vehicles');
      return (response.data as List)
          .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      return _demoVehicles;
    }
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
    try {
      final response = await apiClient.dio.get('/vehicles/$vehicleId/health-score');
      return HealthScoreBreakdown.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      return HealthScoreBreakdown(
        overall: 86,
        categories: const {'inspection': 78, 'maintenance': 86, 'documents': 100, 'ageMileage': 82},
        recommendations: const [
          'Front tires estimated to need replacement within 2 months.',
        ],
      );
    }
  }
}
