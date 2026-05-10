import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/documents/domain/entities/document_category.dart';
import 'package:my_pet/features/documents/domain/entities/pet_document.dart';
import 'package:my_pet/features/documents/domain/repositories/document_repository.dart';
import 'package:my_pet/features/documents/presentation/cubit/documents_list_state.dart';

class DocumentsListCubit extends Cubit<DocumentsListState> {
  DocumentsListCubit({required DocumentRepository repository})
      : _repository = repository,
        super(const DocumentsListInitial());

  final DocumentRepository _repository;
  StreamSubscription<List<PetDocument>>? _subscription;
  String? _householdId;
  String? _petId;

  /// Scope `petId == null` to watch household-wide; pass a pet to scope.
  void start({required String householdId, String? petId}) {
    _householdId = householdId;
    _petId = petId;
    emit(const DocumentsListLoading());
    unawaited(_subscription?.cancel());
    final stream = petId == null
        ? _repository.watchByHousehold(householdId)
        : _repository.watchByPet(householdId, petId);
    _subscription = stream.listen(
      (docs) {
        if (docs.isEmpty) {
          emit(const DocumentsListEmpty());
          return;
        }
        final current = state;
        final uploading =
            current is DocumentsListLoaded && current.uploading;
        emit(DocumentsListLoaded(documents: docs, uploading: uploading));
      },
      onError: (Object error, StackTrace _) {
        emit(DocumentsListError(ServerFailure(message: error.toString())));
      },
    );
  }

  Future<Failure?> upload({
    required String title,
    required DocumentCategory category,
    required String mimeType,
    required File source,
    required String createdBy,
    String? notes,
  }) async {
    final hid = _householdId;
    if (hid == null) return const ServerFailure(message: 'No household.');
    _setUploading(true);
    final result = await _repository.upload(
      householdId: hid,
      petId: _petId,
      createdBy: createdBy,
      title: title,
      category: category,
      mimeType: mimeType,
      source: source,
      notes: notes,
    );
    _setUploading(false);
    return result.fold((f) => f, (_) => null);
  }

  Future<void> delete(String documentId) async {
    final hid = _householdId;
    if (hid == null) return;
    await _repository.delete(hid, documentId);
  }

  void _setUploading(bool value) {
    final current = state;
    if (current is DocumentsListLoaded) {
      emit(current.copyWith(uploading: value));
    } else if (value) {
      emit(const DocumentsListLoading());
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
