import '../../core/api/api_client.dart';
import 'concierge_model.dart';

class ConciergeRepository {
  ConciergeRepository(this.apiClient);

  final ApiClient apiClient;

  static const orderTypes = <String, String>{
    'registration_renewal': 'Registration Renewal',
    'ownership_transfer': 'Ownership Transfer',
    'pickup_delivery': 'Pickup & Delivery',
    'detailing': 'Detailing',
    'driver_service': 'Driver Service',
  };

  Future<ConciergeOrderItem> createOrder({required String orderType, required String vehicleId}) async {
    final response = await apiClient.dio.post('/concierge/orders', data: {
      'orderType': orderType,
      'vehicleId': vehicleId,
    });
    return ConciergeOrderItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ConciergeOrderItem>> fetchMyOrders() async {
    final response = await apiClient.dio.get('/concierge/orders');
    return (response.data as List).map((e) => ConciergeOrderItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}
