import 'dart:typed_data';
import 'package:dio/dio.dart';

/// A file chosen by the user, carried as bytes rather than a path so the same
/// code works on mobile and on web (where picked files have no filesystem path).
class UploadFile {
  const UploadFile({required this.filename, required this.bytes});

  final String filename;
  final Uint8List bytes;

  /// The content type has to be set explicitly — without it the part arrives as
  /// application/octet-stream and the API rejects it as an unsupported type.
  MultipartFile toMultipart() => MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: DioMediaType.parse(mimeTypeFor(filename)),
      );
}

/// Per-request options for uploads, which differ from ordinary calls twice:
///
/// 1. ApiClient's 8s default timeouts are far too short for sending a photo,
///    and `sendTimeout` isn't set globally at all.
/// 2. `retried: true` is set up front so ApiClient's 401 interceptor skips this
///    request. That retry replays `requestOptions` through `dio.fetch`, which
///    cannot work for multipart — the FormData stream is already consumed, so
///    the retry would send an empty body. Surfacing the 401 is the better
///    failure mode.
Options uploadOptions() => Options(
      sendTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      extra: const {'retried': true},
    );

String mimeTypeFor(String filename) {
  final name = filename.toLowerCase();
  if (name.endsWith('.png')) return 'image/png';
  if (name.endsWith('.webp')) return 'image/webp';
  if (name.endsWith('.pdf')) return 'application/pdf';
  return 'image/jpeg';
}
