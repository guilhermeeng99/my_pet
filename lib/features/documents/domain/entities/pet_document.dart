import 'package:equatable/equatable.dart';
import 'package:my_pet/features/documents/domain/entities/document_category.dart';

/// File attached to a household / pet — pet ID card, exam PDF, receipt
/// scan, etc. Stored at `households/{hid}/documents/{documentId}` and
/// mirrored as metadata at `households/{hid}/documents/{documentId}` in
/// Firestore (collection flat per spec).
class PetDocument extends Equatable {
  const PetDocument({
    required this.id,
    required this.householdId,
    required this.title,
    required this.category,
    required this.fileUrl,
    required this.mimeType,
    required this.sizeBytes,
    required this.createdAt,
    required this.createdBy,
    this.petId,
    this.notes,
  });

  final String id;
  final String householdId;

  /// Optional — `null` means the document belongs to the household, not
  /// a specific pet (e.g. clinic contract).
  final String? petId;
  final String title;
  final DocumentCategory category;
  final String fileUrl;
  final String mimeType;
  final int sizeBytes;
  final String? notes;
  final DateTime createdAt;
  final String createdBy;

  bool get isPdf => mimeType == 'application/pdf';
  bool get isImage => mimeType.startsWith('image/');

  PetDocument copyWith({
    String? id,
    String? householdId,
    String? petId,
    String? title,
    DocumentCategory? category,
    String? fileUrl,
    String? mimeType,
    int? sizeBytes,
    String? notes,
    DateTime? createdAt,
    String? createdBy,
    bool clearPet = false,
    bool clearNotes = false,
  }) {
    return PetDocument(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      petId: clearPet ? null : (petId ?? this.petId),
      title: title ?? this.title,
      category: category ?? this.category,
      fileUrl: fileUrl ?? this.fileUrl,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      notes: clearNotes ? null : (notes ?? this.notes),
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        householdId,
        petId,
        title,
        category,
        fileUrl,
        mimeType,
        sizeBytes,
        notes,
        createdAt,
        createdBy,
      ];
}
