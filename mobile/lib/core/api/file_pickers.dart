import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'upload_file.dart';

/// Thin wrappers over the two pickers so screens don't each repeat the
/// bytes-vs-path handling. Both always return bytes, which is what the upload
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

/// A document — PDF or a photo of one.
Future<UploadFile?> pickDocument() async {
  // file_picker 11 exposes pickFiles as a static; the older
  // FilePicker.platform.pickFiles form no longer exists.
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    // Required so bytes are populated on mobile, not just on web.
    withData: true,
  );
  final file = result?.files.single;
  if (file == null || file.bytes == null) return null;
  return UploadFile(filename: file.name, bytes: file.bytes!);
}
