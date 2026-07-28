import 'package:image_picker/image_picker.dart';
import 'upload_file.dart';

/// Thin wrappers over image_picker so screens don't each repeat the
/// bytes-handling. All of these return bytes, which is what the upload
/// endpoints take and what works on web as well as mobile.

/// One photo from the camera or gallery.
Future<UploadFile?> pickImage({required bool fromCamera}) async {
  final picked = await ImagePicker().pickImage(
    source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    // Downscale before upload: phone originals are far larger than a listing
    // thumbnail needs, and the API caps photos at 8 MB.
    maxWidth: 2000,
    imageQuality: 85,
  );
  if (picked == null) return null;
  return UploadFile(filename: picked.name, bytes: await picked.readAsBytes());
}

/// Several photos at once from the gallery, capped at [limit].
Future<List<UploadFile>> pickImages({required int limit}) async {
  final picked = await ImagePicker().pickMultiImage(maxWidth: 2000, imageQuality: 85);
  final files = <UploadFile>[];
  for (final image in picked.take(limit)) {
    files.add(UploadFile(filename: image.name, bytes: await image.readAsBytes()));
  }
  return files;
}

/// A document, captured as a photo.
///
/// Documents are images by design — the API accepts only JPG/PNG/WebP for them
/// (see the vehicle-docs scope in backend storage.service.ts), so every stored
/// document is a plain image to render rather than something needing a PDF
/// viewer. Photographing a registration card or insurance certificate is the
/// normal flow. (No published file_picker version builds against this project's
/// AGP 9 / builtInKotlin=false / compileSdk 36 combination either — see the
/// note in pubspec.yaml.)
Future<UploadFile?> pickDocument({required bool fromCamera}) => pickImage(fromCamera: fromCamera);
