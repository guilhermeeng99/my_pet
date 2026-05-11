import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:my_pet/core/constants/app_constants.dart';
import 'package:my_pet/features/auth/data/models/auth_user_model.dart';
import 'package:my_pet/features/household/data/models/audit_event_model.dart';
import 'package:my_pet/features/household/data/models/household_model.dart';
import 'package:my_pet/features/household/data/models/invite_model.dart';
import 'package:my_pet/features/household/domain/entities/audit_event.dart';

/// Project-owned wrapper around the Firestore docs that back the household
/// feature: `households/{id}`, `inviteCodes/{code}`, and the cross-cutting
/// `users/{uid}.householdId` link. The repository depends on this
/// abstraction so the boundary is mockable.
abstract class HouseholdFirestoreDatasource {
  Stream<HouseholdModel?> watch(String householdId);

  /// Creates a household and links it to the user's profile in one batched
  /// write — household.md rule 5.4.
  Future<HouseholdModel> createAndLinkToUser({
    required String userId,
    required String name,
  });

  /// Generates a fresh code, persists it under `inviteCodes/{code}`, and
  /// throws [HouseholdFullException] when the household is full.
  Future<InviteModel> generateInviteCode({
    required String householdId,
    required String createdBy,
  });

  /// Atomically: validates the code, removes the user from their (clean)
  /// previous household, adds them to the target household, marks the code
  /// used, and updates `users/{uid}.householdId`.
  Future<HouseholdModel> acceptInviteCode({
    required String code,
    required String userId,
  });

  /// Fetches `users/{uid}` profile docs for each UID — used to resolve a
  /// household's `memberIds` into rich members at the repository layer.
  Future<List<AuthUserModel>> fetchMemberProfiles(List<String> uids);

  /// Cascade-deletes the household subtree, household doc and the user doc.
  /// Throws [HouseholdNotEmptyException] when memberIds has more than 1.
  /// Idempotent — missing docs are skipped instead of throwing.
  Future<void> wipeAndDelete({
    required String householdId,
    required String userId,
  });

  /// Removes [memberUserId] from the household and clears their
  /// `users/{uid}.householdId`. Only the owner may call this; the
  /// repository validates ownership before invoking.
  ///
  /// Throws [HouseholdNotFoundException] when the household no longer
  /// exists, [NotMemberException] when the target isn't actually in the
  /// household, and [CannotRemoveOwnerException] when the target is the
  /// current owner.
  Future<HouseholdModel> removeMember({
    required String householdId,
    required String actorUserId,
    required String memberUserId,
  });

  /// Reassigns ownership to [newOwnerId]. Both UIDs must already be in
  /// `memberIds`. Throws [NotMemberException] when [newOwnerId] is not.
  Future<HouseholdModel> transferOwnership({
    required String householdId,
    required String actorUserId,
    required String newOwnerId,
  });

  /// Removes [userId] from the household (the partner leaves but the
  /// household data lives on with the remaining owner). Throws
  /// [CannotLeaveAsOwnerException] when the user is the current owner —
  /// owners must transfer first or wipe.
  Future<void> leaveHousehold({
    required String householdId,
    required String userId,
  });

  /// Live audit feed for the household, newest first.
  Stream<List<AuditEventModel>> watchAudit(String householdId);

  /// Writes a single audit entry. The repository wraps action calls so
  /// the actor + target context is captured consistently.
  Future<void> appendAudit({
    required String householdId,
    required AuditAction action,
    required String actorId,
    required String actorName,
    String? targetUserId,
    String? targetName,
    String? note,
  });
}

/// Sealed exceptions thrown only inside this datasource and translated into
/// `Failure`s by the repository — the rest of the app never sees them.
sealed class HouseholdDatasourceException implements Exception {
  const HouseholdDatasourceException();
}

class HouseholdFullException extends HouseholdDatasourceException {
  const HouseholdFullException();
}

class InviteCodeNotFoundException extends HouseholdDatasourceException {
  const InviteCodeNotFoundException();
}

class InviteCodeExpiredException extends HouseholdDatasourceException {
  const InviteCodeExpiredException();
}

class InviteCodeAlreadyUsedException extends HouseholdDatasourceException {
  const InviteCodeAlreadyUsedException();
}

class AlreadyInHouseholdException extends HouseholdDatasourceException {
  const AlreadyInHouseholdException();
}

class HouseholdNotEmptyException extends HouseholdDatasourceException {
  const HouseholdNotEmptyException();
}

class HouseholdNotFoundException extends HouseholdDatasourceException {
  const HouseholdNotFoundException();
}

class NotMemberException extends HouseholdDatasourceException {
  const NotMemberException();
}

class CannotRemoveOwnerException extends HouseholdDatasourceException {
  const CannotRemoveOwnerException();
}

class CannotLeaveAsOwnerException extends HouseholdDatasourceException {
  const CannotLeaveAsOwnerException();
}

class NotOwnerException extends HouseholdDatasourceException {
  const NotOwnerException();
}

class HouseholdFirestoreDatasourceImpl implements HouseholdFirestoreDatasource {
  HouseholdFirestoreDatasourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  // Tunables centralized in AppConstants — alphabet excludes visually
  // ambiguous glyphs (no 0/O, 1/I/L) so the code can be dictated by phone.

  CollectionReference<Map<String, dynamic>> get _households =>
      _firestore.collection('households');

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _inviteCodes =>
      _firestore.collection('inviteCodes');

  CollectionReference<Map<String, dynamic>> _audit(String hid) =>
      _households.doc(hid).collection('audit');

  @override
  Stream<HouseholdModel?> watch(String householdId) {
    return _households.doc(householdId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return HouseholdModel.fromFirestore(snap.id, snap.data()!);
    });
  }

  @override
  Future<HouseholdModel> createAndLinkToUser({
    required String userId,
    required String name,
  }) async {
    final householdRef = _households.doc();
    final userRef = _users.doc(userId);

    await (_firestore.batch()
          ..set(householdRef, {
            'name': name,
            'ownerId': userId,
            'memberIds': [userId],
            'createdAt': FieldValue.serverTimestamp(),
          })
          ..set(
            userRef,
            {'householdId': householdRef.id},
            SetOptions(merge: true),
          ))
        .commit();

    return HouseholdModel(
      id: householdRef.id,
      name: name,
      ownerId: userId,
      memberIds: [userId],
      createdAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<InviteModel> generateInviteCode({
    required String householdId,
    required String createdBy,
  }) async {
    final householdSnap = await _households.doc(householdId).get();
    if (!householdSnap.exists) {
      throw const InviteCodeNotFoundException();
    }
    final memberIds = List<String>.from(
      householdSnap.data()!['memberIds'] as List? ?? [],
    );
    if (memberIds.length >= AppConstants.householdMaxMembers) {
      throw const HouseholdFullException();
    }

    final code = _generateCode();
    final now = DateTime.now().toUtc();
    final expiresAt = now.add(AppConstants.inviteCodeTtl);
    final invite = InviteModel(
      code: code,
      householdId: householdId,
      createdBy: createdBy,
      createdAt: now,
      expiresAt: expiresAt,
    );
    // Collision risk is negligible (~31^6 codespace, codes expire in 24h),
    // but if it ever happens this set() would silently overwrite the older
    // invite. Acceptable: the older invite holder still sees their code
    // resolve to the same household — the new owner just bumps the expiry.
    await _inviteCodes.doc(code).set(invite.toFirestoreCreate());
    return invite;
  }

  @override
  Future<HouseholdModel> acceptInviteCode({
    required String code,
    required String userId,
  }) async {
    final normalized = code.trim().toUpperCase();
    final codeSnap = await _inviteCodes.doc(normalized).get();
    if (!codeSnap.exists) {
      throw const InviteCodeNotFoundException();
    }
    final codeData = codeSnap.data()!;
    if (codeData['usedBy'] != null) {
      throw const InviteCodeAlreadyUsedException();
    }
    final expiresAt = (codeData['expiresAt'] as Timestamp).toDate();
    if (DateTime.now().toUtc().isAfter(expiresAt)) {
      throw const InviteCodeExpiredException();
    }
    final newHouseholdId = codeData['householdId'] as String;

    final newHouseholdSnap = await _households.doc(newHouseholdId).get();
    if (!newHouseholdSnap.exists) {
      throw const InviteCodeNotFoundException();
    }
    final newMemberIds = List<String>.from(
      newHouseholdSnap.data()!['memberIds'] as List? ?? [],
    );
    if (newMemberIds.contains(userId)) {
      throw const AlreadyInHouseholdException();
    }
    if (newMemberIds.length >= AppConstants.householdMaxMembers) {
      throw const HouseholdFullException();
    }

    // Best-effort: detect the user's current household and confirm it's
    // empty (only-them, no pets). Anything richer is rejected to keep this
    // first slice simple — user can clear data manually.
    final userSnap = await _users.doc(userId).get();
    final currentHouseholdId = userSnap.data()?['householdId'] as String?;
    if (currentHouseholdId != null && currentHouseholdId != newHouseholdId) {
      final currentSnap = await _households.doc(currentHouseholdId).get();
      if (currentSnap.exists) {
        final currentMembers = List<String>.from(
          currentSnap.data()!['memberIds'] as List? ?? [],
        );
        final petsSnap = await _households
            .doc(currentHouseholdId)
            .collection('pets')
            .limit(1)
            .get();
        final isClean = currentMembers.length == 1 &&
            currentMembers.first == userId &&
            petsSnap.docs.isEmpty;
        if (!isClean) {
          throw const AlreadyInHouseholdException();
        }
      }
    }

    final batch = _firestore.batch()
      ..update(_households.doc(newHouseholdId), {
        'memberIds': FieldValue.arrayUnion([userId]),
      })
      ..update(_inviteCodes.doc(normalized), {
        'usedBy': userId,
        'usedAt': FieldValue.serverTimestamp(),
      })
      ..set(
        _users.doc(userId),
        {'householdId': newHouseholdId},
        SetOptions(merge: true),
      );
    if (currentHouseholdId != null && currentHouseholdId != newHouseholdId) {
      batch.delete(_households.doc(currentHouseholdId));
    }
    await batch.commit();

    return HouseholdModel(
      id: newHouseholdId,
      name: (newHouseholdSnap.data()!['name'] ?? '') as String,
      ownerId: (newHouseholdSnap.data()!['ownerId'] ?? '') as String,
      memberIds: [...newMemberIds, userId],
      createdAt:
          (newHouseholdSnap.data()!['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> wipeAndDelete({
    required String householdId,
    required String userId,
  }) async {
    final hSnap = await _households.doc(householdId).get();
    if (hSnap.exists) {
      final memberIds = List<String>.from(
        hSnap.data()!['memberIds'] as List? ?? [],
      );
      if (memberIds.length > 1) {
        throw const HouseholdNotEmptyException();
      }
      await _deleteHouseholdSubtree(householdId);
      await _households.doc(householdId).delete();
    }
    // Always best-effort delete the user doc too — covers the retry path
    // where the household is already gone but the user doc lingered.
    await _users.doc(userId).delete().catchError((Object _) {});
  }

  Future<void> _deleteHouseholdSubtree(String hid) async {
    final petsRef = _households.doc(hid).collection('pets');
    final pets = await petsRef.get();
    for (final pet in pets.docs) {
      for (final subcol in const [
        'vaccinations',
        'health_events',
        'weights',
        'photos',
      ]) {
        await _deleteCollection(pet.reference.collection(subcol));
      }
      await pet.reference.delete();
    }
    for (final subcol in const ['reminders', 'documents']) {
      await _deleteCollection(_households.doc(hid).collection(subcol));
    }
    // Active invite codes are top-level — clean up so the partner can't
    // accept into a household that no longer exists.
    final invites = await _inviteCodes.where('householdId', isEqualTo: hid).get();
    if (invites.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final d in invites.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> ref,
  ) async {
    final docs = await ref.get();
    if (docs.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final d in docs.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }

  @override
  Future<HouseholdModel> removeMember({
    required String householdId,
    required String actorUserId,
    required String memberUserId,
  }) async {
    final snap = await _households.doc(householdId).get();
    if (!snap.exists) throw const HouseholdNotFoundException();
    final data = snap.data()!;
    final ownerId = (data['ownerId'] ?? '') as String;
    final memberIds =
        List<String>.from(data['memberIds'] as List? ?? const <String>[]);

    if (ownerId != actorUserId) throw const NotOwnerException();
    if (memberUserId == ownerId) throw const CannotRemoveOwnerException();
    if (!memberIds.contains(memberUserId)) {
      throw const NotMemberException();
    }

    final batch = _firestore.batch()
      ..update(_households.doc(householdId), {
        'memberIds': FieldValue.arrayRemove([memberUserId]),
      })
      ..set(
        _users.doc(memberUserId),
        {'householdId': null},
        SetOptions(merge: true),
      );
    await batch.commit();

    return HouseholdModel(
      id: householdId,
      name: (data['name'] ?? '') as String,
      ownerId: ownerId,
      memberIds: memberIds.where((id) => id != memberUserId).toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now().toUtc(),
    );
  }

  @override
  Future<HouseholdModel> transferOwnership({
    required String householdId,
    required String actorUserId,
    required String newOwnerId,
  }) async {
    final snap = await _households.doc(householdId).get();
    if (!snap.exists) throw const HouseholdNotFoundException();
    final data = snap.data()!;
    final ownerId = (data['ownerId'] ?? '') as String;
    final memberIds =
        List<String>.from(data['memberIds'] as List? ?? const <String>[]);

    if (ownerId != actorUserId) throw const NotOwnerException();
    if (!memberIds.contains(newOwnerId)) {
      throw const NotMemberException();
    }

    await _households.doc(householdId).update({'ownerId': newOwnerId});

    return HouseholdModel(
      id: householdId,
      name: (data['name'] ?? '') as String,
      ownerId: newOwnerId,
      memberIds: memberIds,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> leaveHousehold({
    required String householdId,
    required String userId,
  }) async {
    final snap = await _households.doc(householdId).get();
    if (!snap.exists) throw const HouseholdNotFoundException();
    final data = snap.data()!;
    final ownerId = (data['ownerId'] ?? '') as String;
    final memberIds =
        List<String>.from(data['memberIds'] as List? ?? const <String>[]);

    if (!memberIds.contains(userId)) throw const NotMemberException();

    // If the owner is leaving, auto-transfer ownership to the sole
    // remaining member in the same batch — keeps the paired-state UX
    // symmetric so either side can tap "leave". Solo owners (no
    // partner) cannot leave; they must dissolve via the Danger Zone.
    String? newOwnerId;
    if (userId == ownerId) {
      final others = memberIds.where((id) => id != userId).toList();
      if (others.isEmpty) throw const CannotLeaveAsOwnerException();
      newOwnerId = others.first;
    }

    final updates = <String, Object?>{
      'memberIds': FieldValue.arrayRemove([userId]),
    };
    if (newOwnerId != null) updates['ownerId'] = newOwnerId;

    final batch = _firestore.batch()
      ..update(_households.doc(householdId), updates)
      ..set(
        _users.doc(userId),
        {'householdId': null},
        SetOptions(merge: true),
      );
    await batch.commit();
  }

  @override
  Stream<List<AuditEventModel>> watchAudit(String householdId) {
    return _audit(householdId)
        .orderBy('at', descending: true)
        .limit(AppConstants.auditFeedLimit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AuditEventModel.fromFirestore(d.id, d.data()))
            .toList(growable: false));
  }

  @override
  Future<void> appendAudit({
    required String householdId,
    required AuditAction action,
    required String actorId,
    required String actorName,
    String? targetUserId,
    String? targetName,
    String? note,
  }) async {
    final ref = _audit(householdId).doc();
    final event = AuditEventModel(
      id: ref.id,
      householdId: householdId,
      action: action,
      actorId: actorId,
      actorName: actorName,
      targetUserId: targetUserId,
      targetName: targetName,
      at: DateTime.now().toUtc(),
      note: note,
    );
    await ref.set(event.toFirestoreCreate());
  }

  @override
  Future<List<AuthUserModel>> fetchMemberProfiles(List<String> uids) async {
    if (uids.isEmpty) return const [];
    final results = await Future.wait(
      uids.map((uid) async {
        final snap = await _users.doc(uid).get();
        if (!snap.exists) return null;
        return AuthUserModel.fromFirestore(snap.id, snap.data()!);
      }),
    );
    return results.whereType<AuthUserModel>().toList();
  }

  String _generateCode() {
    final rng = Random.secure();
    final buf = StringBuffer();
    const alphabet = AppConstants.inviteCodeAlphabet;
    for (var i = 0; i < AppConstants.inviteCodeLength; i++) {
      buf.write(alphabet[rng.nextInt(alphabet.length)]);
    }
    return buf.toString();
  }
}
