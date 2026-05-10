import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:my_pet/app/di/injection_container.dart';
import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_radii.dart';
import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/app/widgets/app_field.dart';
import 'package:my_pet/app/widgets/app_primary_button.dart';
import 'package:my_pet/app/widgets/circle_icon_button.dart';
import 'package:my_pet/app/widgets/pet_mascot.dart';
import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/core/services/photo_storage_service.dart';
import 'package:my_pet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:my_pet/features/pets/domain/entities/pet.dart';
import 'package:my_pet/features/pets/domain/entities/sex.dart';
import 'package:my_pet/features/pets/domain/entities/species.dart';
import 'package:my_pet/features/pets/presentation/cubit/pet_form_cubit.dart';
import 'package:my_pet/features/pets/presentation/widgets/species_meta.dart';
import 'package:my_pet/gen/strings.g.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:uuid/uuid.dart';

/// Create or edit a pet. When [existing] is null we are in create mode.
class PetFormPage extends StatelessWidget {
  const PetFormPage({super.key, this.existing});

  final Pet? existing;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PetFormCubit>(
      create: (_) => sl<PetFormCubit>(),
      child: _PetFormView(existing: existing),
    );
  }
}

class _PetFormView extends StatefulWidget {
  const _PetFormView({this.existing});
  final Pet? existing;

  @override
  State<_PetFormView> createState() => _PetFormViewState();
}

class _PetFormViewState extends State<_PetFormView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _breedCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _microchipCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _picker = ImagePicker();

  Species _species = Species.cat;
  Sex _sex = Sex.unknown;
  bool _neutered = false;
  DateTime? _birthDate;
  DateTime? _adoptionDate;

  // Pet id is generated up-front so the photo upload can write to the final
  // path (`households/{hid}/pets/{petId}/profile.jpg`) before the Firestore
  // doc is committed. Reused on submit.
  late final String _petId;
  String? _photoUrl;
  bool _uploadingPhoto = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _petId = e?.id ?? const Uuid().v4();
    if (e == null) return;
    _nameCtrl.text = e.name;
    _breedCtrl.text = e.breed ?? '';
    _colorCtrl.text = e.color ?? '';
    _microchipCtrl.text = e.microchipId ?? '';
    _notesCtrl.text = e.notes ?? '';
    _species = e.species;
    _sex = e.sex;
    _neutered = e.neutered;
    _birthDate = e.birthDate;
    _adoptionDate = e.adoptionDate;
    _photoUrl = e.photoUrl;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    _colorCtrl.dispose();
    _microchipCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat.yMMMd();
    return BlocConsumer<PetFormCubit, PetFormState>(
      listener: (context, state) {
        if (state is PetFormSuccess) {
          context.pop();
        } else if (state is PetFormError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(t.pets.form.errors.saveFailed)),
            );
        }
      },
      builder: (context, state) {
        final submitting = state is PetFormSubmitting;
        return Scaffold(
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.md,
                        AppSpacing.md,
                      ),
                      children: [
                        _FormHeader(
                          isEdit: _isEdit,
                          photoUrl: _photoUrl,
                          uploading: _uploadingPhoto,
                          onPickPhoto: _pickPhoto,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppField(
                          icon: PhosphorIconsBold.pawPrint,
                          label: t.pets.form.name,
                          child: TextFormField(
                            controller: _nameCtrl,
                            decoration: _bareDecoration(
                              t.pets.form.namePlaceholder,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? t.pets.form.errors.nameRequired
                                : null,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AppField(
                                icon: PhosphorIconsBold.cat,
                                label: t.pets.form.species,
                                child: DropdownButtonFormField<Species>(
                                  initialValue: _species,
                                  decoration: _bareDecoration(null),
                                  isExpanded: true,
                                  items: Species.values
                                      .map((s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(
                                              SpeciesMeta.label(s),
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _species = v ?? _species),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: AppField(
                                icon: PhosphorIconsBold.identificationCard,
                                label: t.pets.form.sex,
                                child: DropdownButtonFormField<Sex>(
                                  initialValue: _sex,
                                  decoration: _bareDecoration(null),
                                  isExpanded: true,
                                  items: Sex.values
                                      .map((s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(SexMeta.label(s)),
                                          ))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _sex = v ?? _sex),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AppField(
                                icon: PhosphorIconsBold.calendarBlank,
                                label: t.pets.form.birthDate,
                                child: _DateInline(
                                  value: _birthDate,
                                  formatter: dateFmt,
                                  onPick: (d) =>
                                      setState(() => _birthDate = d),
                                  firstDate: DateTime(
                                    DateTime.now().year - 30,
                                  ),
                                  lastDate: DateTime.now(),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: AppField(
                                icon: PhosphorIconsBold.heart,
                                label: t.pets.form.adoptionDate,
                                child: _DateInline(
                                  value: _adoptionDate,
                                  formatter: dateFmt,
                                  onPick: (d) =>
                                      setState(() => _adoptionDate = d),
                                  firstDate: DateTime(
                                    DateTime.now().year - 30,
                                  ),
                                  lastDate: DateTime.now(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppField(
                          icon: PhosphorIconsBold.tag,
                          label: t.pets.form.breed,
                          child: TextFormField(
                            controller: _breedCtrl,
                            decoration: _bareDecoration(
                              t.pets.form.breedPlaceholder,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppField(
                          icon: PhosphorIconsBold.palette,
                          label: t.pets.form.color,
                          child: TextFormField(
                            controller: _colorCtrl,
                            decoration: _bareDecoration(
                              t.pets.form.colorPlaceholder,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppField(
                          icon: PhosphorIconsBold.barcode,
                          label: t.pets.form.microchipId,
                          child: TextFormField(
                            controller: _microchipCtrl,
                            decoration: _bareDecoration(
                              t.pets.form.microchipPlaceholder,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _NeuteredCard(
                          value: _neutered,
                          onChanged: (v) => setState(() => _neutered = v),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppField(
                          icon: PhosphorIconsBold.notePencil,
                          label: t.pets.form.notesOptional,
                          child: TextFormField(
                            controller: _notesCtrl,
                            decoration: _bareDecoration(
                              t.pets.form.notesPlaceholder,
                            ),
                            maxLines: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: AppPrimaryButton(
                      label: t.pets.form.save,
                      loading: submitting,
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _bareDecoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<void> _pickPhoto() async {
    if (_uploadingPhoto) return;
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 90,
    );
    if (picked == null) return;
    if (!mounted) return;

    final auth = context.read<AuthBloc>().state;
    final householdId = switch (auth) {
      AuthAuthenticated(:final user) => user.householdId,
      AuthNeedsHousehold(:final user) => user.householdId,
      _ => null,
    };
    if (householdId == null) return;

    setState(() => _uploadingPhoto = true);
    final result = await sl<PhotoStorageService>().uploadPetProfile(
      householdId: householdId,
      petId: _petId,
      source: File(picked.path),
    );
    if (!mounted) return;
    setState(() => _uploadingPhoto = false);
    result.fold(
      (failure) {
        final message = failure is PhotoTooLargeFailure
            ? t.pets.form.errors.photoTooLarge
            : t.pets.form.errors.photoUploadFailed;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      },
      (url) => setState(() => _photoUrl = url),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthBloc>().state;
    final user = switch (auth) {
      AuthAuthenticated(:final user) => user,
      AuthNeedsHousehold(:final user) => user,
      _ => null,
    };
    if (user == null || user.householdId == null) return;

    final now = DateTime.now().toUtc();
    final draft = Pet(
      id: _petId,
      householdId: user.householdId!,
      name: _nameCtrl.text.trim(),
      species: _species,
      sex: _sex,
      neutered: _neutered,
      breed: _breedCtrl.text.trim().isEmpty ? null : _breedCtrl.text.trim(),
      birthDate: _birthDate,
      adoptionDate: _adoptionDate,
      color: _colorCtrl.text.trim().isEmpty ? null : _colorCtrl.text.trim(),
      microchipId:
          _microchipCtrl.text.trim().isEmpty ? null : _microchipCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      allergies: widget.existing?.allergies ?? const <String>[],
      photoUrl: _photoUrl,
      currentWeightKg: widget.existing?.currentWeightKg,
      archivedAt: widget.existing?.archivedAt,
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
      createdBy: widget.existing?.createdBy ?? user.uid,
    );

    final cubit = context.read<PetFormCubit>();
    (_isEdit ? cubit.update(draft) : cubit.create(draft)).ignore();
  }
}

class _FormHeader extends StatelessWidget {
  const _FormHeader({
    required this.isEdit,
    required this.photoUrl,
    required this.uploading,
    required this.onPickPhoto,
  });

  final bool isEdit;
  final String? photoUrl;
  final bool uploading;
  final VoidCallback onPickPhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleIconButton(
          icon: PhosphorIconsBold.arrowLeft,
          onTap: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit
                        ? t.pets.form.editTitle
                        : t.pets.form.createTitle,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    isEdit
                        ? t.pets.form.editSubtitle
                        : t.pets.form.createSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.palette.onSurfaceMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _PetPhotoSlot(
              photoUrl: photoUrl,
              uploading: uploading,
              onTap: onPickPhoto,
            ),
          ],
        ),
      ],
    );
  }
}

class _PetPhotoSlot extends StatelessWidget {
  const _PetPhotoSlot({
    required this.photoUrl,
    required this.uploading,
    required this.onTap,
  });

  final String? photoUrl;
  final bool uploading;
  final VoidCallback onTap;

  static const double _size = 110;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final palette = context.palette;
    final label =
        hasPhoto ? t.pets.form.photo.changeAria : t.pets.form.photo.addAria;

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: uploading ? null : onTap,
        borderRadius: AppRadii.brXL,
        child: Stack(
          alignment: Alignment.bottomRight,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: AppRadii.brXL,
              ),
              clipBehavior: Clip.antiAlias,
              child: hasPhoto
                  ? CachedNetworkImage(
                      imageUrl: photoUrl!,
                      width: _size,
                      height: _size,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => ColoredBox(
                        color: theme.colorScheme.primaryContainer,
                      ),
                      errorWidget: (_, _, _) => const PetMascot(size: _size),
                    )
                  : const PetMascot(size: _size),
            ),
            if (uploading)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.30),
                    borderRadius: AppRadii.brXL,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              Positioned(
                right: 6,
                bottom: 6,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.onPrimary,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    hasPhoto
                        ? PhosphorIconsBold.pencilSimple
                        : PhosphorIconsBold.camera,
                    size: 14,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            // Faint outline ring so the slot still reads on white photos.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: AppRadii.brXL,
                    border: Border.all(color: palette.outline),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeuteredCard extends StatelessWidget {
  const _NeuteredCard({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: AppRadii.brLg,
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm + 2,
          AppSpacing.sm,
          AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppRadii.brLg,
          border: Border.all(color: context.palette.outline, width: 1.2),
        ),
        child: Row(
          children: [
            Icon(
              PhosphorIconsBold.shieldCheck,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t.pets.form.neutered, style: theme.textTheme.titleSmall),
                  Text(
                    t.pets.form.neuteredHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.palette.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateInline extends StatelessWidget {
  const _DateInline({
    required this.value,
    required this.formatter,
    required this.onPick,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime? value;
  final DateFormat formatter;
  final ValueChanged<DateTime?> onPick;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: firstDate,
          lastDate: lastDate,
        );
        if (picked != null) onPick(picked);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value == null ? t.pets.form.selectDate : formatter.format(value!),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: value == null ? palette.onSurfaceFaint : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: () => onPick(null),
                child: Icon(
                  PhosphorIconsRegular.x,
                  size: 16,
                  color: palette.onSurfaceFaint,
                ),
              )
            else
              Icon(
                PhosphorIconsRegular.caretDown,
                size: 16,
                color: palette.onSurfaceFaint,
              ),
          ],
        ),
      ),
    );
  }
}
