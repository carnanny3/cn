import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import 'partner_model.dart';

class ServicesRepository {
  ServicesRepository(this.apiClient);

  final ApiClient apiClient;

  static const categories = <String, String>{
    'oil_change': 'Oil Change',
    'general_service': 'General Service',
    'brakes': 'Brake Service',
    'battery': 'Battery Replacement',
    'ac_repair': 'AC Repair',
    'tires': 'Tire Replacement',
    'detailing': 'Detailing',
  };

  Future<List<PartnerResult>> searchGarages(String serviceCategory, {double? lat, double? lng}) async {
    try {
      final response = await apiClient.dio.get('/partners/search', queryParameters: {
        'serviceCategory': serviceCategory,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      });
      return (response.data as List)
          .map((e) => PartnerResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      return [
        PartnerResult(id: 'demo-garage-1', businessName: 'Al Fahim Auto Care', ratingAvg: 4.8, price: 180, distanceKm: 3.2, durationEstimateMinutes: 45),
      ];
    }
  }

  Future<Map<String, dynamic>> createBooking({
    required String bookingType,
    required String vehicleId,
    String? partnerId,
    String? serviceCategory,
    required DateTime scheduledAt,
    required double totalAmount,
    bool pickupDeliveryRequested = false,
  }) async {
    final response = await apiClient.dio.post('/bookings', data: {
      'bookingType': bookingType,
      'vehicleId': vehicleId,
      if (partnerId != null) 'partnerId': partnerId,
      if (serviceCategory != null) 'serviceCategory': serviceCategory,
      'scheduledAt': scheduledAt.toIso8601String(),
      'totalAmount': totalAmount,
      'pickupDeliveryRequested': pickupDeliveryRequested,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> fetchBookings() async {
    try {
      final response = await apiClient.dio.get('/bookings');
      return List<Map<String, dynamic>>.from(response.data as List);
    } on DioException {
      return [];
    }
  }
}
