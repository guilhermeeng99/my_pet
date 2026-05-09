import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_pet/features/household/data/repositories/household_repository_impl.dart';

import '../../../../harness/factories/auth_user_factory.dart';
import '../../../../harness/factories/household_factory.dart';
import '../../../../harness/mocks.dart';

void main() {
  late MockHouseholdFirestoreDatasource datasource;
  late HouseholdRepositoryImpl repository;

  setUp(() {
    datasource = MockHouseholdFirestoreDatasource();
    repository = HouseholdRepositoryImpl(datasource: datasource);
  });

  group('createForUser', () {
    test("uses '{displayName}'s family' as default name", () async {
      final user = AuthUserFactory.build(displayName: 'Jane');
      when(
        () => datasource.createAndLinkToUser(
          userId: any(named: 'userId'),
          name: any(named: 'name'),
        ),
      ).thenAnswer((_) async => HouseholdFactory.buildModel());

      final result = await repository.createForUser(user);

      expect(result.isRight(), isTrue);
      verify(
        () => datasource.createAndLinkToUser(
          userId: 'uid_123',
          name: "Jane's family",
        ),
      ).called(1);
    });

    test("falls back to 'My family' when displayName is missing", () async {
      final user = AuthUserFactory.build(displayName: null);
      when(
        () => datasource.createAndLinkToUser(
          userId: any(named: 'userId'),
          name: any(named: 'name'),
        ),
      ).thenAnswer((_) async => HouseholdFactory.buildModel(name: 'My family'));

      await repository.createForUser(user);

      verify(
        () => datasource.createAndLinkToUser(
          userId: 'uid_123',
          name: 'My family',
        ),
      ).called(1);
    });
  });
}
