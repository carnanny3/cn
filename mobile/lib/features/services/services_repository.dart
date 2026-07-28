import '../../core/api/api_client.dart';
import '../../l10n/generated/app_localizations.dart';
import '../bookings/booking_model.dart';
import 'partner_model.dart';

class ServicesRepository {
  ServicesRepository(this.apiClient);

  final ApiClient apiClient;

  /// Categories a customer can book directly, in the order the services grid
  /// shows them. Deliberately not every category that can appear on a booking —
  /// see [categoryLabel].
  static const categoryKeys = <String>[
    'oil_change',
    'general_service',
    'brakes',
    'battery',
    'ac_repair',
    'tires',
    'detailing',
  ];

  /// Label for any service category the backend can produce, which is a wider
  /// set than [categoryKeys] — a warranty claim approved for repair creates a
  /// booking under 'warranty_repair' that nobody books directly.
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
      case 'warranty_repair':
        return l10n.serviceWarrantyRepair;
      default:
        // serviceCategory is a free-form column, so an unrecognised value is
        // always possible. Showing "Some New Thing" reads as an oversight;
        // showing "some_new_thing" reads as a bug.
        return _humanize(key);
    }
  }

  static String _humanize(String key) => key
      .split('_')
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');

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
