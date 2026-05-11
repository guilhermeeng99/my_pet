import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:my_pet/app/di/injection_container.dart';
import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_radii.dart';
import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/app/widgets/app_card.dart';
import 'package:my_pet/app/widgets/app_primary_button.dart';
import 'package:my_pet/app/widgets/circle_icon_button.dart';
import 'package:my_pet/app/widgets/feature_list_card.dart';
import 'package:my_pet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:my_pet/features/documents/domain/entities/document_category.dart';
import 'package:my_pet/features/documents/domain/entities/pet_document.dart';
import 'package:my_pet/features/documents/presentation/cubit/documents_list_cubit.dart';
import 'package:my_pet/features/documents/presentation/cubit/documents_list_state.dart';
import 'package:my_pet/features/documents/presentation/widgets/document_category_meta.dart';
import 'package:my_pet/gen/strings.g.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class PetDocumentsArgs {
  const PetDocumentsArgs({
    required this.householdId,
    required this.petId,
    required this.petName,
  });

  final String householdId;
  final String petId;
  final String petName;
}

class PetDocumentsPage extends StatelessWidget {
  const PetDocumentsPage({
    required this.householdId,
    required this.petId,
    required this.petName,
    super.key,
  });

  final String householdId;
  final String petId;
  final String petName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DocumentsListCubit>(
      create: (_) => DocumentsListCubit(repository: sl())
        ..start(householdId: householdId, petId: petId),
      child: _DocumentsView(petName: petName),
    );
  }
}

class _DocumentsView extends StatelessWidget {
  const _DocumentsView({required this.petName});
  final String petName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.sm),
              BlocBuilder<DocumentsListCubit, DocumentsListState>(
                buildWhen: (a, b) =>
                    (a is DocumentsListLoaded) != (b is DocumentsListLoaded),
                builder: (context, state) {
                  final showAdd = state is DocumentsListLoaded;
                  return _Header(
                    onAdd: showAdd ? () => _openSheet(context) : null,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child:
                    BlocBuilder<DocumentsListCubit, DocumentsListState>(
                  builder: (context, state) {
                    return switch (state) {
                      DocumentsListInitial() ||
                      DocumentsListLoading() =>
                        const Center(child: CircularProgressIndicator()),
                      DocumentsListEmpty() => _Empty(
                          onAdd: () => _openSheet(context),
                        ),
                      DocumentsListLoaded() => _List(state: state),
                      DocumentsListError() => Center(
                          child: Text(t.documents.errors.loadFailed),
                        ),
                    };
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSheet(BuildContext context) async {
    final cubit = context.read<DocumentsListCubit>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => BlocProvider.value(
        value: cubit,
        child: const _UploadSheet(),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final addCallback = onAdd;
    return Row(
      children: [
        CircleIconButton(
          icon: PhosphorIconsBold.arrowLeft,
          onTap: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            t.documents.tabTitle,
            style: theme.textTheme.headlineLarge,
          ),
        ),
        if (addCallback != null)
          CircleIconButton(
            icon: PhosphorIconsBold.plus,
            onTap: addCallback,
            tooltip: t.documents.addDocument,
          ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return ListView(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      children: [
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: AppRadii.brXL,
            ),
            child: Icon(
              PhosphorIconsBold.folderOpen,
              size: 48,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          t.documents.empty.title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          t.documents.empty.subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: palette.onSurfaceMuted),
        ),
        const SizedBox(height: AppSpacing.lg),
        FeatureListCard(
          icon: PhosphorIconsRegular.plus,
          title: t.documents.addDocument,
          onTap: onAdd,
        ),
      ],
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.state});
  final DocumentsListLoaded state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        for (final doc in state.documents) ...[
          _DocumentTile(document: doc),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.document});
  final PetDocument document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final dateFmt = DateFormat.yMMMd();
    return AppCard(
      onTap: () => _open(context),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: AppRadii.brMd,
            ),
            child: Icon(
              DocumentCategoryMeta.icon(document.category),
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(document.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '${DocumentCategoryMeta.label(document.category)} · '
                  '${_formatSize(document.sizeBytes)} · '
                  '${dateFmt.format(document.createdAt.toLocal())}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.onSurfaceMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _confirmDelete(context),
            tooltip: t.common.delete,
            icon: Icon(
              PhosphorIconsRegular.trash,
              color: palette.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    if (document.isImage) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _DocumentImageViewer(document: document),
        ),
      );
      return;
    }
    // PDFs (and other non-image types) — copy the URL to the clipboard so
    // the user can paste it into any external viewer / share sheet.
    await Clipboard.setData(ClipboardData(text: document.fileUrl));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(t.documents.linkCopied)),
      );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.documents.deleteConfirmTitle),
        content: Text(t.documents.deleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.common.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<DocumentsListCubit>().delete(document.id);
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _DocumentImageViewer extends StatelessWidget {
  const _DocumentImageViewer({required this.document});
  final PetDocument document;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          document.title,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: InteractiveViewer(
          maxScale: 4,
          child: CachedNetworkImage(
            imageUrl: document.fileUrl,
            fit: BoxFit.contain,
            placeholder: (_, _) =>
                const Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }
}

class _UploadSheet extends StatefulWidget {
  const _UploadSheet();

  @override
  State<_UploadSheet> createState() => _UploadSheetState();
}

class _UploadSheetState extends State<_UploadSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DocumentCategory _category = DocumentCategory.other;
  File? _file;
  String? _mimeType;
  bool _busy = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                color: palette.outline,
                borderRadius: AppRadii.brPill,
              ),
            ),
            Text(
              t.documents.upload.title,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            _FilePickerRow(
              file: _file,
              onPick: _pickFile,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: t.documents.upload.titleLabel,
                prefixIcon: const Icon(PhosphorIconsBold.notePencil),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? t.common.required
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<DocumentCategory>(
              initialValue: _category,
              decoration: InputDecoration(
                labelText: t.documents.upload.category,
                prefixIcon: const Icon(PhosphorIconsBold.folder),
              ),
              items: DocumentCategory.values
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(DocumentCategoryMeta.label(c)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _notesCtrl,
              decoration: InputDecoration(
                labelText: t.documents.upload.notesOptional,
                prefixIcon: const Icon(PhosphorIconsBold.notePencil),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.md),
            AppPrimaryButton(
              label: t.documents.upload.save,
              loading: _busy,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final file = File(picked.path);
    final mime = picked.mimeType ?? _inferMimeFromName(picked.name);
    setState(() {
      _file = file;
      _mimeType = mime;
      if (_titleCtrl.text.isEmpty) _titleCtrl.text = picked.name;
    });
  }

  String _inferMimeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) {
      return 'image/heic';
    }
    return 'image/jpeg';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_file == null || _mimeType == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(t.documents.upload.errors.noFile)),
        );
      return;
    }
    setState(() => _busy = true);
    final auth = context.read<AuthBloc>().state;
    final uid = switch (auth) {
      AuthAuthenticated(:final user) => user.uid,
      _ => '',
    };
    final failure = await context.read<DocumentsListCubit>().upload(
          title: _titleCtrl.text.trim(),
          category: _category,
          mimeType: _mimeType!,
          source: _file!,
          createdBy: uid,
          notes: _notesCtrl.text.trim().isEmpty
              ? null
              : _notesCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure == null) {
      Navigator.of(context).pop();
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(t.documents.errors.uploadFailed)),
      );
  }
}

class _FilePickerRow extends StatelessWidget {
  const _FilePickerRow({required this.file, required this.onPick});
  final File? file;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return InkWell(
      onTap: onPick,
      borderRadius: AppRadii.brLg,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: palette.surfaceMuted,
          borderRadius: AppRadii.brLg,
          border: Border.all(color: palette.outline),
        ),
        child: Row(
          children: [
            Icon(
              PhosphorIconsBold.uploadSimple,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                file == null
                    ? t.documents.upload.pickFile
                    : (file!.uri.pathSegments.lastOrNull ??
                        t.documents.upload.fileSelected),
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              PhosphorIconsRegular.caretRight,
              color: palette.onSurfaceFaint,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
