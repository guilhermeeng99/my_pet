import 'package:equatable/equatable.dart';

/// Shared family unit. Owner has admin rights, members can read/write but
/// not manage other members or hard-delete pets. See
/// [`specs/household.md`](../../../../../specs/household.md).
class Household extends Equatable {
  const Household({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.memberIds,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String ownerId;
  final List<String> memberIds;
  final DateTime createdAt;

  bool isOwner(String userId) => ownerId == userId;
  bool isMember(String userId) => memberIds.contains(userId);

  Household copyWith({
    String? id,
    String? name,
    String? ownerId,
    List<String>? memberIds,
    DateTime? createdAt,
  }) {
    return Household(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, ownerId, memberIds, createdAt];
}
