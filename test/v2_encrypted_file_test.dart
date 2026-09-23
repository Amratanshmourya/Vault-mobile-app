import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vault/core/services/encrypted_file_service.dart';
import 'package:vault/data/models/encrypted_file_attachment.dart';

void main() {
  group('V2 Encrypted File Attachments Tests', () {
    test('Formats file sizes appropriately into human readable strings', () {
      final att1 = EncryptedFileAttachment(
        id: '1',
        fileName: 'id_passport.jpg',
        encryptedRelativePath: '1.enc',
        fileSizeBytes: 500,
        mimeType: 'image/jpeg',
        createdAt: DateTime(2026, 9, 23),
      );
      expect(att1.formattedSize, equals('500 B'));

      final att2 = EncryptedFileAttachment(
        id: '2',
        fileName: 'document.pdf',
        encryptedRelativePath: '2.enc',
        fileSizeBytes: 2048 * 1024,
        mimeType: 'application/pdf',
        createdAt: DateTime(2026, 9, 23),
      );
      expect(att2.formattedSize, equals('2.0 MB'));
    });

    test('Serializes and deserializes attachment JSON metadata', () {
      final attachment = EncryptedFileAttachment(
        id: 'test-id',
        fileName: 'seed_phrase.txt',
        encryptedRelativePath: 'seed_phrase.txt.enc',
        fileSizeBytes: 1024,
        mimeType: 'text/plain',
        createdAt: DateTime(2026, 9, 23),
      );

      final json = attachment.toJson();
      final restored = EncryptedFileAttachment.fromJson(json);

      expect(restored.id, equals(attachment.id));
      expect(restored.fileName, equals(attachment.fileName));
      expect(restored.fileSizeBytes, equals(attachment.fileSizeBytes));
      expect(restored.mimeType, equals(attachment.mimeType));
      expect(restored.encryptedRelativePath, equals(attachment.encryptedRelativePath));
    });

    test('Enforces maximum attachment file size threshold (25MB)', () {
      final service = EncryptedFileService();
      final hugeData = Uint8List(EncryptedFileService.maxFileSizeBytes + 100);
      final key = SecretKey([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32]);

      expect(
        () async => await service.encryptAndSaveFile(
          fileBytes: hugeData,
          fileName: 'oversized.iso',
          secretKey: key,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
