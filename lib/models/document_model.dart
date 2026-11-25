class UserDocumentItem {
  const UserDocumentItem({
    required this.id,
    required this.userId,
    this.applicationId,
    required this.title,
    this.documentType,
    required this.fileUrl,
    this.storagePath,
    this.fileName,
    this.fileSizeBytes,
    this.mimeType,
    required this.status, // 'pending', 'verified', 'rejected'
    this.verificationNotes,
    required this.createdAt,
    this.updatedAt,
    this.userName,
    this.userEmail,
  });

  final String id;
  final String userId;
  final String? applicationId;
  final String title;
  final String? documentType;
  final String fileUrl;
  final String? storagePath;
  final String? fileName;
  final int? fileSizeBytes;
  final String? mimeType;
  final String status;
  final String? verificationNotes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? userName;
  final String? userEmail;

  bool get isVerified => status == 'verified';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';

  String get formattedSize {
    if (fileSizeBytes == null || fileSizeBytes! <= 0) return 'Unknown size';
    final kb = fileSizeBytes! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  factory UserDocumentItem.fromMap(
    Map<String, dynamic> map, {
    String? userName,
    String? userEmail,
  }) {
    return UserDocumentItem(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      applicationId: map['application_id']?.toString(),
      title: map['title']?.toString() ?? 'Document',
      documentType: map['document_type']?.toString(),
      fileUrl: map['file_url']?.toString() ?? '',
      storagePath: map['storage_path']?.toString(),
      fileName: map['file_name']?.toString(),
      fileSizeBytes: (map['file_size_bytes'] as num?)?.toInt(),
      mimeType: map['mime_type']?.toString(),
      status: map['status']?.toString() ?? 'pending',
      verificationNotes: map['verification_notes']?.toString(),
      createdAt: map['created_at'] != null
          ? (DateTime.tryParse(map['created_at'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())?.toLocal()
          : null,
      userName: userName,
      userEmail: userEmail,
    );
  }
}
