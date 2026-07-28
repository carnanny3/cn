import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/api/upload_file.dart';
import 'vehicle_document_model.dart';
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

  Future<List<VehicleDocument>> fetchDocuments(String vehicleId) async {
    final response = await apiClient.dio.get('/vehicles/$vehicleId/documents');
    return (response.data as List)
        .map((e) => VehicleDocument.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Vehicle> fetchVehicle(String vehicleId) async {
    final response = await apiClient.dio.get('/vehicles/$vehicleId');
    return Vehicle.fromJson(response.data as Map<String, dynamic>);
  }

  Future<VehicleDocument> uploadDocument({
    required String vehicleId,
    required String type,
    required UploadFile file,
  }) async {
    final formData = FormData.fromMap({'type': type, 'file': file.toMultipart()});
    final response = await apiClient.dio.post(
      '/vehicles/$vehicleId/documents',
      data: formData,
      options: uploadOptions(),
    );
    return VehicleDocument.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Vehicle> uploadVehiclePhoto({required String vehicleId, required UploadFile file}) async {
    final formData = FormData.fromMap({'file': file.toMultipart()});
    final response = await apiClient.dio.post(
      '/vehicles/$vehicleId/photo',
      data: formData,
      options: uploadOptions(),
    );
    return Vehicle.fromJson(response.data as Map<String, dynamic>);
  }
}
