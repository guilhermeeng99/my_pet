import 'package:equatable/equatable.dart';

/// Photo in a pet's gallery. Storage is at
/// `households/{hid}/pets/{petId}/gallery/{id}/{original|thumb}.jpg`;
/// Firestore mirror lives at `households/{hid}/pets/{petId}/photos/{id}`.
class PetPhoto extends Equatable {
  const PetPhoto({
    required this.id,
    required this.householdId,
    required this.petId,
    required this.url,
    required this.thumbnailUrl,
    required this.createdAt,
    required this.createdBy,
    this.caption,
    this.takenAt,
  });

  final String id;
  final String householdId;
  final String petId;
  final String url;
  final String thumbnailUrl;
  final String? caption;
  final DateTime? takenAt;
  final DateTime createdAt;
  final String createdBy;

  PetPhoto copyWith({
    String? id,
    String? householdId,
    String? petId,
    String? url,
    String? thumbnailUrl,
    String? caption,
    DateTime? takenAt,
    DateTime? createdAt,
    String? createdBy,
    bool clearCaption = false,
    bool clearTakenAt = false,
  }) {
    return PetPhoto(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      petId: petId ?? this.petId,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: clearCaption ? null : (caption ?? this.caption),
      takenAt: clearTakenAt ? null : (takenAt ?? this.takenAt),
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        householdId,
        petId,
        url,
        thumbnailUrl,
        caption,
        takenAt,
        createdAt,
        createdBy,
      ];
}
