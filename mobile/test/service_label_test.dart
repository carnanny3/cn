import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:car_nanny/l10n/generated/app_localizations.dart';
import 'package:car_nanny/features/services/services_repository.dart';

void main() {
  late AppLocalizations en;
  late AppLocalizations ar;

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
    ar = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  group('ServicesRepository.categoryLabel', () {
    test('labels every category a customer can book', () {
      for (final key in ServicesRepository.categoryKeys) {
        final label = ServicesRepository.categoryLabel(en, key);
        expect(label, isNotEmpty);
        // A label equal to the key means the switch fell through to the
        // humanising fallback, i.e. a bookable category has no translation.
        expect(label, isNot(key), reason: '$key has no label');
      }
    });

    test('labels warranty_repair, which the warranty flow creates but nobody books', () {
      // Approving a claim for repair creates a booking under this category
      // (backend warranty.service.ts), so it needs a label even though it is
      // absent from categoryKeys.
      expect(ServicesRepository.categoryLabel(en, 'warranty_repair'), 'Warranty Repair');
      expect(ServicesRepository.categoryLabel(ar, 'warranty_repair'), isNot('warranty_repair'));
    });

    test('humanises an unrecognised category instead of leaking snake_case', () {
      expect(ServicesRepository.categoryLabel(en, 'some_future_service'), 'Some Future Service');
      expect(ServicesRepository.categoryLabel(en, 'windscreen'), 'Windscreen');
    });

    test('translates known categories in Arabic', () {
      final label = ServicesRepository.categoryLabel(ar, 'oil_change');
      expect(label, isNot('oil_change'));
      expect(label, isNot(ServicesRepository.categoryLabel(en, 'oil_change')));
    });
  });
}
