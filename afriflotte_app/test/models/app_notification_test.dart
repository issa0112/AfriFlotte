import 'package:flutter_test/flutter_test.dart';
import 'package:afriflotte_app/models/app_notification.dart';

void main() {
  group('AppNotification.fromJson', () {
    test('parses an unread notification', () {
      final notification = AppNotification.fromJson({
        'id': 2,
        'type_notification': 'NOUVELLE_PROPOSITION',
        'type_notification_libelle': 'Nouvelle proposition',
        'message': 'Nouvelle proposition de Iso Transport pour Bamako → Gao : 300000.00 FCFA.',
        'lue': false,
        'created_at': '2026-08-11T04:03:50Z',
      });

      expect(notification.type, 'NOUVELLE_PROPOSITION');
      expect(notification.lue, isFalse);
      expect(notification.message, contains('Bamako'));
    });

    test('defaults lue to false when absent', () {
      final notification = AppNotification.fromJson({
        'id': 1,
        'type_notification': 'MISSION_CREEE',
        'message': 'Une mission a été créée.',
      });

      expect(notification.lue, isFalse);
      expect(notification.typeLibelle, '');
    });
  });
}
