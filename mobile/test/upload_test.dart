import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:car_nanny/core/api/upload_file.dart';
import 'package:car_nanny/features/listings/listing_thumbnail.dart';

void main() {
  group('mimeTypeFor', () {
    test('maps the extensions the API accepts', () {
      expect(mimeTypeFor('mulkiya.pdf'), 'application/pdf');
      expect(mimeTypeFor('car.png'), 'image/png');
      expect(mimeTypeFor('car.webp'), 'image/webp');
      expect(mimeTypeFor('car.jpg'), 'image/jpeg');
      expect(mimeTypeFor('car.jpeg'), 'image/jpeg');
    });

    test('ignores extension casing', () {
      expect(mimeTypeFor('SCAN.PDF'), 'application/pdf');
      expect(mimeTypeFor('PHOTO.PNG'), 'image/png');
    });
  });

  group('UploadFile', () {
    test('sets the content type on the multipart part', () {
      // Without an explicit content type the part arrives as
      // application/octet-stream and the API rejects it as unsupported.
      final file = UploadFile(filename: 'doc.pdf', bytes: Uint8List(4));
      expect(file.toMultipart().contentType.toString(), 'application/pdf');
    });
  });

  group('ListingThumbnail', () {
    testWidgets('falls back to a car icon when there is no photo', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ListingThumbnail(url: null)));
      expect(find.byIcon(Icons.directions_car_outlined), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('falls back for an empty url too', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ListingThumbnail(url: '')));
      expect(find.byIcon(Icons.directions_car_outlined), findsOneWidget);
    });

    testWidgets('renders an image when a photo url is present', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ListingThumbnail(url: 'http://localhost:3000/uploads/listing-photos/a/b.png')),
      );
      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.directions_car_outlined), findsNothing);
    });
  });
}
