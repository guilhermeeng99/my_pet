import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_pet/features/documents/domain/entities/document_category.dart';
import 'package:my_pet/features/documents/domain/entities/pet_document.dart';
import 'package:my_pet/features/documents/presentation/cubit/documents_list_cubit.dart';
import 'package:my_pet/features/documents/presentation/cubit/documents_list_state.dart';

import '../../../../harness/mocks.dart';

PetDocument _doc(String id, {String? petId}) => PetDocument(
      id: id,
      householdId: 'h',
      petId: petId,
      title: 'Doc $id',
      category: DocumentCategory.other,
      fileUrl: 'https://example.com/$id.pdf',
      mimeType: 'application/pdf',
      sizeBytes: 1024,
      createdAt: DateTime.utc(2026, 5, 10),
      createdBy: 'uid_123',
    );

void main() {
  late MockDocumentRepository repository;

  setUp(() {
    repository = MockDocumentRepository();
  });

  DocumentsListCubit buildCubit() => DocumentsListCubit(repository: repository);

  group('DocumentsListCubit', () {
    blocTest<DocumentsListCubit, DocumentsListState>(
      'household scope: subscribes to watchByHousehold',
      build: () {
        when(() => repository.watchByHousehold('h'))
            .thenAnswer((_) => Stream<List<PetDocument>>.value([_doc('a')]));
        return buildCubit();
      },
      act: (cubit) => cubit.start(householdId: 'h'),
      verify: (cubit) {
        verify(() => repository.watchByHousehold('h')).called(1);
        verifyNever(() => repository.watchByPet(any(), any()));
        expect(cubit.state, isA<DocumentsListLoaded>());
      },
    );

    blocTest<DocumentsListCubit, DocumentsListState>(
      'pet scope: subscribes to watchByPet',
      build: () {
        when(() => repository.watchByPet('h', 'p'))
            .thenAnswer((_) => Stream<List<PetDocument>>.value(const []));
        return buildCubit();
      },
      act: (cubit) => cubit.start(householdId: 'h', petId: 'p'),
      expect: () => [
        const DocumentsListLoading(),
        const DocumentsListEmpty(),
      ],
    );

    blocTest<DocumentsListCubit, DocumentsListState>(
      'stream error surfaces DocumentsListError',
      build: () {
        when(() => repository.watchByHousehold('h'))
            .thenAnswer((_) => Stream<List<PetDocument>>.error(Exception()));
        return buildCubit();
      },
      act: (cubit) => cubit.start(householdId: 'h'),
      expect: () => [
        const DocumentsListLoading(),
        isA<DocumentsListError>(),
      ],
    );
  });
}
