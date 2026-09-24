import 'package:flutter_test/flutter_test.dart';
import 'package:vault/data/models/vault_item.dart';

void main() {
  group('V3 Custom Fields 2.0 Tests', () {
    test('Serializes and deserializes Custom Fields 2.0 with all types', () {
      final fields = [
        CustomField(label: 'Security Pin', value: '4928', type: CustomFieldType.number),
        CustomField(label: 'Recovery Email', value: 'backup@me.com', type: CustomFieldType.email),
        CustomField(label: 'API Secret', value: 'sk_live_12345', type: CustomFieldType.secret),
        CustomField(label: 'Admin Portal', value: 'https://admin.acme.corp', type: CustomFieldType.url),
        CustomField(label: 'Auto Renew', value: 'true', type: CustomFieldType.boolean),
        CustomField(label: 'Renewal Date', value: '2028-12-31', type: CustomFieldType.date),
        CustomField(label: 'Server Notes', value: 'Line 1\nLine 2', type: CustomFieldType.multiline),
      ];

      final item = VaultItem(
        type: VaultItemType.login,
        title: 'Acme Cloud Server',
        customFields: fields,
      );

      final json = item.toJson();
      final roundTrip = VaultItem.fromJson(json);

      expect(roundTrip.customFields.length, 7);
      expect(roundTrip.customFields[0].type, CustomFieldType.number);
      expect(roundTrip.customFields[0].value, '4928');

      expect(roundTrip.customFields[1].type, CustomFieldType.email);
      expect(roundTrip.customFields[2].type, CustomFieldType.secret);
      expect(roundTrip.customFields[2].isConcealed, isTrue);

      expect(roundTrip.customFields[4].type, CustomFieldType.boolean);
      expect(roundTrip.customFields[4].value, 'true');

      expect(roundTrip.customFields[5].type, CustomFieldType.date);
      expect(roundTrip.customFields[6].type, CustomFieldType.multiline);
    });

    test('Backwards compatibility: maps legacy isConcealed to CustomFieldType.secret', () {
      final legacyJson = {
        'label': 'Legacy Question',
        'value': 'Fluffy',
        'isConcealed': true,
      };

      final cf = CustomField.fromJson(legacyJson);
      expect(cf.type, CustomFieldType.secret);
      expect(cf.isConcealed, isTrue);
      expect(cf.value, 'Fluffy');
    });
  });
}
