import '../../core/api/api_client.dart';
import '../../l10n/generated/app_localizations.dart';
import '../bookings/booking_model.dart';
import 'partner_model.dart';

class ServicesRepository {
  ServicesRepository(this.apiClient);

  final ApiClient apiClient;

  /// Service category IDs — stable, used as API values and lookup keys.
  static const categoryKeys = <String>[
    'oil_change',
    'general_service',
    'brakes',
    'battery',
    'ac_repair',
    'tires',
    'detailing',
  ];

  static String categoryLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'oil_change':
        return l10n.serviceOilChange;
      case 'general_service':
        return l10n.serviceGeneralService;
      case 'brakes':
        return l10n.serviceBrakes;
      case 'battery':
        return l10n.serviceBattery;
      case 'ac_repair':
        return l10n.serviceAcRepair;
      case 'tires':
        return l10n.serviceTires;
      case 'detailing':
        return l10n.serviceDetailing;
      default:
        return key;
    }
  }

  Future<List<PartnerResult>> searchGarages(String serviceCategory, {double? lat, double? lng}) async {
    final response = await apiClient.dio.get('/partners/search', queryParameters: {
      'serviceCategory': serviceCategory,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    });
    return (response.data as List)
        .map((e) => PartnerResult.fromJson(e as Map<String, dynamic>))
        .toList();
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

  Future<List<Booking>> fetchBookings() async {
    final response = await apiClient.dio.get('/bookings');
    return (response.data as List).map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> cancelBooking(String id) async {
    await apiClient.dio.post('/bookings/$id/cancel');
  }
}
