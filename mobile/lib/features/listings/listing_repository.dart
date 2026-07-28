import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/api/upload_file.dart';
import 'listing_model.dart';

class ListingRepository {
  ListingRepository(this.apiClient);

  final ApiClient apiClient;

  Future<List<VehicleListingItem>> browseActive({String? make}) async {
    final response = await apiClient.dio.get('/listings', queryParameters: {
      if (make != null && make.isNotEmpty) 'make': make,
    });
    return (response.data as List).map((e) => VehicleListingItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<VehicleListingItem> getOne(String id) async {
    final response = await apiClient.dio.get('/listings/$id');
    return VehicleListingItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<VehicleListingItem>> compare(List<String> ids) async {
    final response = await apiClient.dio.get('/listings/compare', queryParameters: {'ids': ids.join(',')});
    return (response.data as List).map((e) => VehicleListingItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<VehicleListingItem>> fetchMyListings() async {
    final response = await apiClient.dio.get('/listings/mine');
    return (response.data as List).map((e) => VehicleListingItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Uploads photos ahead of the listing itself and returns the URLs to submit
  /// with [createListing] — the API only accepts photo URLs it issued here.
  Future<List<String>> uploadPhotos(List<UploadFile> files) async {
    final formData = FormData();
    for (final file in files) {
      formData.files.add(MapEntry('files', file.toMultipart()));
    }
    final response = await apiClient.dio.post(
      '/listings/photos',
      data: formData,
      options: uploadOptions(),
    );
    return ((response.data as Map<String, dynamic>)['urls'] as List).map((e) => e as String).toList();
  }

  Future<VehicleListingItem> createListing({
    String? vehicleId,
    required String make,
    required String model,
    required int year,
    int? mileageKm,
    required double askingPrice,
    List<String>? photoUrls,
  }) async {
    final response = await apiClient.dio.post('/listings', data: {
      if (vehicleId != null) 'vehicleId': vehicleId,
      'make': make,
      'model': model,
      'year': year,
      if (mileageKm != null) 'mileageKm': mileageKm,
      'askingPrice': askingPrice,
      if (photoUrls != null && photoUrls.isNotEmpty) 'photoUrls': photoUrls,
    });
    return VehicleListingItem.fromJson(response.data as Map<String, dynamic>);
  }
}
