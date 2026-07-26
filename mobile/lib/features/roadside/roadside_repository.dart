import '../../core/api/api_client.dart';
import 'roadside_model.dart';

class RoadsideRepository {
  RoadsideRepository(this.apiClient);

  final ApiClient apiClient;

  static const serviceTypes = <String, String>{
    'tow': 'Tow Truck',
    'jumpstart': 'Jump Start',
    'flat_tire': 'Flat Tire',
    'fuel_delivery': 'Fuel Delivery',
    'lockout': 'Lockout',
  };

  Future<RoadsideRequestItem> createRequest({
    required String vehicleId,
    required String serviceType,
    required double lat,
    required double lng,
  }) async {
    final response = await apiClient.dio.post('/roadside/requests', data: {
      'vehicleId': vehicleId,
      'serviceType': serviceType,
      'location': {'lat': lat, 'lng': lng},
    });
    return RoadsideRequestItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RoadsideRequestItem> track(String id) async {
    final response = await apiClient.dio.get('/roadside/requests/$id/track');
    return RoadsideRequestItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> cancel(String id) async {
    await apiClient.dio.post('/roadside/requests/$id/cancel');
  }

  Future<List<RoadsideRequestItem>> fetchMyRequests() async {
    final response = await apiClient.dio.get('/roadside/requests');
    return (response.data as List).map((e) => RoadsideRequestItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<RoadsideRequestItem>> fetchAssignedToMe() async {
    final response = await apiClient.dio.get('/roadside/requests/assigned/mine');
    return (response.data as List).map((e) => RoadsideRequestItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> updateStatus(String id, String status) async {
    await apiClient.dio.patch('/roadside/requests/$id/status', data: {'status': status});
  }
}
