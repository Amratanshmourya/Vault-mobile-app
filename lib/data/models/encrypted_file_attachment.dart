class EncryptedFileAttachment {
  final String id;
  final String fileName;
  final int fileSizeBytes;
  final String mimeType;
  final String encryptedRelativePath;
  final DateTime createdAt;

  const EncryptedFileAttachment({
    required this.id,
    required this.fileName,
    required this.fileSizeBytes,
    required this.mimeType,
    required this.encryptedRelativePath,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'fileName': fileName,
    'fileSizeBytes': fileSizeBytes,
    'mimeType': mimeType,
    'encryptedRelativePath': encryptedRelativePath,
    'createdAt': createdAt.toIso8601String(),
  };

  factory EncryptedFileAttachment.fromJson(Map<String, dynamic> json) =>
      EncryptedFileAttachment(
        id: json['id'] as String? ?? '',
        fileName: json['fileName'] as String? ?? 'attachment',
        fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
        mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
        encryptedRelativePath: json['encryptedRelativePath'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
