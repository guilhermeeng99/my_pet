import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/household/data/datasources/household_firestore_datasource.dart';
import 'package:my_pet/features/household/data/repositories/household_repository_impl.dart';
import 'package:my_pet/features/household/domain/entities/audit_event.dart';
import 'package:my_pet/features/household/domain/entities/household_member.dart';

import '../../../../harness/factories/auth_user_factory.dart';
import '../../../../harness/factories/household_factory.dart';
import '../../../../harness/mocks.dart';

void main() {
  late MockHouseholdFirestoreDatasource datasource;
  late HouseholdRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(AuditAction.householdCreated);
  });

  setUp(() {
    datasource = MockHouseholdFirestoreDatasource();
    repository = HouseholdRepositoryImpl(datasource: datasource);

    // Audit writes are best-effort — default to success.
    when(() => datasource.appendAudit(
          householdId: any(named: 'householdId'),
          action: any(named: 'action'),
          actorId: any(named: 'actorId'),
          actorName: any(named: 'actorName'),
          targetUserId: any(named: 'targetUserId'),
          targetName: any(named: 'targetName'),
          note: any(named: 'note'),
        )).thenAnswer((_) async {});
  });

  group('removeMember', () {
    test('writes an audit entry on success', () async {
      final owner = AuthUserFactory.withHousehold();
      final household = HouseholdFactory.buildModel(
        memberIds: ['uid_123', 'partner_456'],
      );
      const partner = HouseholdMember(
        uid: 'partner_456',
        email: 'partner@example.com',
        role: HouseholdRole.partner,
        displayName: 'Sam',
      );
      when(() => datasource.removeMember(
            householdId: any(named: 'householdId'),
            actorUserId: any(named: 'actorUserId'),
            memberUserId: any(named: 'memberUserId'),
          )).thenAnswer((_) async => household);

      final result = await repository.removeMember(
        householdId: household.id,
        actor: owner,
        target: partner,
      );

      expect(result.isRight(), isTrue);
      verify(() => datasource.appendAudit(
            householdId: household.id,
            action: AuditAction.memberRemoved,
            actorId: owner.uid,
            actorName: any(named: 'actorName'),
            targetUserId: 'partner_456',
            targetName: 'Sam',
            note: any(named: 'note'),
          )).called(1);
    });

    test('maps NotOwnerException to PermissionFailure', () async {
      final owner = AuthUserFactory.withHousehold();
      const partner = HouseholdMember(
        uid: 'partner_456',
        email: 'partner@example.com',
        role: HouseholdRole.partner,
      );
      when(() => datasource.removeMember(
            householdId: any(named: 'householdId'),
            actorUserId: any(named: 'actorUserId'),
            memberUserId: any(named: 'memberUserId'),
          )).thenThrow(const NotOwnerException());

      final result = await repository.removeMember(
        householdId: 'h',
        actor: owner,
        target: partner,
      );

      result.fold(
        (f) => expect(f, isA<PermissionFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('leaveHousehold', () {
    test('writes audit before leaving so the actor still has perms',
        () async {
      final partner = AuthUserFactory.build(
        uid: 'partner_456',
        householdId: 'h',
      );
      when(() => datasource.leaveHousehold(
            householdId: any(named: 'householdId'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async {});

      final result = await repository.leaveHousehold(
        householdId: 'h',
        actor: partner,
      );

      expect(result.isRight(), isTrue);
      verifyInOrder([
        () => datasource.appendAudit(
              householdId: 'h',
              action: AuditAction.memberLeft,
              actorId: partner.uid,
              actorName: any(named: 'actorName'),
              targetUserId: partner.uid,
              targetName: any(named: 'targetName'),
              note: any(named: 'note'),
            ),
        () => datasource.leaveHousehold(
              householdId: 'h',
              userId: partner.uid,
            ),
      ]);
    });

    test('maps CannotLeaveAsOwnerException to ValidationFailure',
        () async {
      final owner = AuthUserFactory.withHousehold();
      when(() => datasource.leaveHousehold(
            householdId: any(named: 'householdId'),
            userId: any(named: 'userId'),
          )).thenThrow(const CannotLeaveAsOwnerException());

      final result = await repository.leaveHousehold(
        householdId: 'h',
        actor: owner,
      );

      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('transferOwnership', () {
    test('writes audit on success', () async {
      final owner = AuthUserFactory.withHousehold();
      final household = HouseholdFactory.buildModel(
        memberIds: ['uid_123', 'partner_456'],
        ownerId: 'partner_456',
      );
      const partner = HouseholdMember(
        uid: 'partner_456',
        email: 'partner@example.com',
        role: HouseholdRole.partner,
        displayName: 'Sam',
      );
      when(() => datasource.transferOwnership(
            householdId: any(named: 'householdId'),
            actorUserId: any(named: 'actorUserId'),
            newOwnerId: any(named: 'newOwnerId'),
          )).thenAnswer((_) async => household);

      final result = await repository.transferOwnership(
        householdId: household.id,
        actor: owner,
        newOwner: partner,
      );

      expect(result.isRight(), isTrue);
      verify(() => datasource.appendAudit(
            householdId: household.id,
            action: AuditAction.ownerTransferred,
            actorId: owner.uid,
            actorName: any(named: 'actorName'),
            targetUserId: 'partner_456',
            targetName: 'Sam',
            note: any(named: 'note'),
          )).called(1);
    });
  });
}
