import 'package:flutter/widgets.dart';
import 'package:my_pet/features/documents/domain/entities/document_category.dart';
import 'package:my_pet/gen/strings.g.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DocumentCategoryMeta {
  static IconData icon(DocumentCategory c) => switch (c) {
        DocumentCategory.petId => PhosphorIconsBold.identificationCard,
        DocumentCategory.exam => PhosphorIconsBold.flask,
        DocumentCategory.receipt => PhosphorIconsBold.receipt,
        DocumentCategory.contract => PhosphorIconsBold.fileText,
        DocumentCategory.prescription => PhosphorIconsBold.pill,
        DocumentCategory.other => PhosphorIconsBold.folder,
      };

  static String label(DocumentCategory c) => switch (c) {
        DocumentCategory.petId => t.documents.categories.petId,
        DocumentCategory.exam => t.documents.categories.exam,
        DocumentCategory.receipt => t.documents.categories.receipt,
        DocumentCategory.contract => t.documents.categories.contract,
        DocumentCategory.prescription => t.documents.categories.prescription,
        DocumentCategory.other => t.documents.categories.other,
      };
}
