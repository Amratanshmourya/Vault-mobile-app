import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/encrypted_file_attachment.dart';
import '../crypto/aes_gcm_service.dart';

class EncryptedFileService {
  final AesGcmService _aesGcm = AesGcmService();
  static const int maxFileSizeBytes = 25 * 1024 * 1024; // 25 MB default limit

  Future<Directory> _getEncryptedFilesDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/encrypted_attachments');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Encrypts a local file from disk or in-memory bytes and stores the encrypted payload in app storage
  Future<EncryptedFileAttachment> encryptAndSaveFile({
    File? sourceFile,
    Uint8List? fileBytes,
    String? fileName,
    required SecretKey secretKey,
  }) async {
    final bytes = fileBytes ?? (sourceFile != null ? await sourceFile.readAsBytes() : null);
    if (bytes == null) {
      throw Exception('No file data provided.');
    }

    if (bytes.length > maxFileSizeBytes) {
      throw Exception('File size exceeds the 25 MB attachment limit.');
    }

    final rawName = fileName ??
        (sourceFile != null ? sourceFile.path.split(Platform.pathSeparator).last : 'file_${DateTime.now().millisecondsSinceEpoch}');
    final fileId = const Uuid().v4();
    final encryptedDir = await _getEncryptedFilesDir();
    final relativePath = '$fileId.enc';
    final targetFile = File('${encryptedDir.path}/$relativePath');

    // Encrypt raw bytes with AES-256-GCM
    final encryptedPayload = await _aesGcm.encrypt(
      plainText: String.fromCharCodes(bytes),
      secretKey: secretKey,
    );

    await targetFile.writeAsString(encryptedPayload.serialize(), flush: true);

    String mimeType = 'application/octet-stream';
    final ext = rawName.toLowerCase();
    if (ext.endsWith('.pdf')) mimeType = 'application/pdf';
    if (ext.endsWith('.png')) mimeType = 'image/png';
    if (ext.endsWith('.jpg') || ext.endsWith('.jpeg')) mimeType = 'image/jpeg';
    if (ext.endsWith('.txt')) mimeType = 'text/plain';

    return EncryptedFileAttachment(
      id: fileId,
      fileName: rawName,
      fileSizeBytes: bytes.length,
      mimeType: mimeType,
      encryptedRelativePath: relativePath,
      createdAt: DateTime.now(),
    );
  }

  /// Decrypts an encrypted file into memory buffer on-demand for viewing/exporting
  Future<Uint8List> decryptFileToMemory({
    required EncryptedFileAttachment attachment,
    required SecretKey secretKey,
  }) async {
    final encryptedDir = await _getEncryptedFilesDir();
    final targetFile = File('${encryptedDir.path}/${attachment.encryptedRelativePath}');

    if (!await targetFile.exists()) {
      throw Exception('Encrypted attachment file not found on disk.');
    }

    final rawPayload = await targetFile.readAsString();
    final payload = EncryptedPayload.deserialize(rawPayload);

    final decryptedString = await _aesGcm.decrypt(
      payload: payload,
      secretKey: secretKey,
    );

    return Uint8List.fromList(decryptedString.codeUnits);
  }

  /// Decrypts attachment directly in memory
  Future<Uint8List> decryptAttachmentInMemory({
    required EncryptedFileAttachment attachment,
    required SecretKey secretKey,
  }) {
    return decryptFileToMemory(attachment: attachment, secretKey: secretKey);
  }

  /// Permanently deletes an encrypted attachment from storage
  Future<void> deleteEncryptedFile(EncryptedFileAttachment attachment) async {
    try {
      final encryptedDir = await _getEncryptedFilesDir();
      final targetFile = File('${encryptedDir.path}/${attachment.encryptedRelativePath}');
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
    } catch (_) {}
  }
}
