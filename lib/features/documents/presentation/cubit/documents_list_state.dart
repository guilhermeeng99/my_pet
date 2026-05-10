import 'package:equatable/equatable.dart';
import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/documents/domain/entities/pet_document.dart';

sealed class DocumentsListState extends Equatable {
  const DocumentsListState();
  @override
  List<Object?> get props => const [];
}

class DocumentsListInitial extends DocumentsListState {
  const DocumentsListInitial();
}

class DocumentsListLoading extends DocumentsListState {
  const DocumentsListLoading();
}

class DocumentsListEmpty extends DocumentsListState {
  const DocumentsListEmpty();
}

class DocumentsListLoaded extends DocumentsListState {
  const DocumentsListLoaded({
    required this.documents,
    required this.uploading,
  });

  /// Newest-first.
  final List<PetDocument> documents;
  final bool uploading;

  DocumentsListLoaded copyWith({
    List<PetDocument>? documents,
    bool? uploading,
  }) =>
      DocumentsListLoaded(
        documents: documents ?? this.documents,
        uploading: uploading ?? this.uploading,
      );

  @override
  List<Object?> get props => [documents, uploading];
}

class DocumentsListError extends DocumentsListState {
  const DocumentsListError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
