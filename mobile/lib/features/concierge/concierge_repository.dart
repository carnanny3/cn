import '../../core/api/api_client.dart';
import '../../l10n/generated/app_localizations.dart';
import 'concierge_model.dart';

class ConciergeRepository {
  ConciergeRepository(this.apiClient);

  final ApiClient apiClient;

  /// Order type IDs — stable, used as API values and lookup keys.
  static const orderTypeKeys = <String>[
    'registration_renewal',
    'ownership_transfer',
    'pickup_delivery',
    'detailing',
    'driver_service',
  ];

  static String orderTypeLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'registration_renewal':
        return l10n.conciergeOrderTypeRegistrationRenewal;
      case 'ownership_transfer':
        return l10n.conciergeOrderTypeOwnershipTransfer;
      case 'pickup_delivery':
        return l10n.conciergeOrderTypePickupDelivery;
      case 'detailing':
        return l10n.conciergeOrderTypeDetailing;
      case 'driver_service':
        return l10n.conciergeOrderTypeDriverService;
      default:
        return key;
    }
  }

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
