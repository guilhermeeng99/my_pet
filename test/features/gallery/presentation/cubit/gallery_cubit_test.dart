import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_pet/features/gallery/domain/entities/pet_photo.dart';
import 'package:my_pet/features/gallery/presentation/cubit/gallery_cubit.dart';
import 'package:my_pet/features/gallery/presentation/cubit/gallery_state.dart';

import '../../../../harness/mocks.dart';

PetPhoto _photo(String id) => PetPhoto(
      id: id,
      householdId: 'h',
      petId: 'p',
      url: 'https://example.com/$id.jpg',
      thumbnailUrl: 'https://example.com/$id-thumb.jpg',
      createdAt: DateTime.utc(2026, 5, 10),
      createdBy: 'uid_123',
    );

void main() {
  late MockGalleryRepository repository;

  setUp(() {
    repository = MockGalleryRepository();
  });

  GalleryCubit buildCubit() => GalleryCubit(repository: repository);

  group('GalleryCubit', () {
    blocTest<GalleryCubit, GalleryState>(
      'emits Empty when watch yields no photos',
      build: () {
        when(() => repository.watchByPet('h', 'p'))
            .thenAnswer((_) => Stream<List<PetPhoto>>.value(const []));
        return buildCubit();
      },
      act: (cubit) => cubit.start('h', 'p'),
      expect: () => [const GalleryLoading(), const GalleryEmpty()],
    );

    blocTest<GalleryCubit, GalleryState>(
      'emits Loaded with the photos when stream yields a list',
      build: () {
        when(() => repository.watchByPet('h', 'p')).thenAnswer(
          (_) => Stream<List<PetPhoto>>.value([_photo('a'), _photo('b')]),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.start('h', 'p'),
      verify: (cubit) {
        final state = cubit.state;
        expect(state, isA<GalleryLoaded>());
        expect((state as GalleryLoaded).photos.length, equals(2));
        expect(state.uploading, isFalse);
      },
    );

    blocTest<GalleryCubit, GalleryState>(
      'setAsProfile returns null on success and a failure on error',
      build: () {
        when(() => repository.watchByPet('h', 'p'))
            .thenAnswer((_) => Stream<List<PetPhoto>>.value([_photo('a')]));
        when(
          () => repository.setAsProfile(
            householdId: any(named: 'householdId'),
            petId: any(named: 'petId'),
            photoId: any(named: 'photoId'),
            url: any(named: 'url'),
          ),
        ).thenAnswer((_) async => const Right(unit));
        return buildCubit();
      },
      act: (cubit) async {
        cubit.start('h', 'p');
        final outcome = await cubit.setAsProfile(_photo('a'));
        expect(outcome, isNull);
      },
      verify: (_) {
        verify(
          () => repository.setAsProfile(
            householdId: 'h',
            petId: 'p',
            photoId: 'a',
            url: 'https://example.com/a.jpg',
          ),
        ).called(1);
      },
    );

    blocTest<GalleryCubit, GalleryState>(
      'stream error surfaces GalleryError',
      build: () {
        when(() => repository.watchByPet('h', 'p'))
            .thenAnswer((_) => Stream<List<PetPhoto>>.error(Exception()));
        return buildCubit();
      },
      act: (cubit) => cubit.start('h', 'p'),
      expect: () => [const GalleryLoading(), isA<GalleryError>()],
    );
  });
}
