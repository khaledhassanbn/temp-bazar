import 'package:bazar_suez/services/independent_courier/independent_courier_settings_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeEffectiveEnabled logic', () {
    test('global enabled + store inherit => enabled', () {
      expect(
        IndependentCourierSettingsService.computeEffectiveEnabled(
          globalEnabled: true,
          storeOverride: null,
        ),
        true,
      );
    });

    test('global enabled + store enabled => enabled', () {
      expect(
        IndependentCourierSettingsService.computeEffectiveEnabled(
          globalEnabled: true,
          storeOverride: true,
        ),
        true,
      );
    });

    test('global enabled + store disabled => disabled', () {
      expect(
        IndependentCourierSettingsService.computeEffectiveEnabled(
          globalEnabled: true,
          storeOverride: false,
        ),
        false,
      );
    });

    test('global disabled + store enabled => disabled', () {
      expect(
        IndependentCourierSettingsService.computeEffectiveEnabled(
          globalEnabled: false,
          storeOverride: true,
        ),
        false,
      );
    });

    test('global disabled + store inherit => disabled', () {
      expect(
        IndependentCourierSettingsService.computeEffectiveEnabled(
          globalEnabled: false,
          storeOverride: null,
        ),
        false,
      );
    });
  });
}
