import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:my_pet/app/di/injection_container.dart';
import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_radii.dart';
import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/app/widgets/app_field.dart';
import 'package:my_pet/app/widgets/app_primary_button.dart';
import 'package:my_pet/app/widgets/circle_icon_button.dart';
import 'package:my_pet/core/data/vaccine_presets.dart';
import 'package:my_pet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:my_pet/features/pets/domain/entities/species.dart';
import 'package:my_pet/features/vaccinations/domain/entities/vaccination.dart';
import 'package:my_pet/features/vaccinations/domain/entities/vaccine_category.dart';
import 'package:my_pet/features/vaccinations/presentation/cubit/vaccination_form_cubit.dart';
import 'package:my_pet/features/vaccinations/presentation/widgets/vaccination_meta.dart';
import 'package:my_pet/gen/strings.g.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:uuid/uuid.dart';

class VaccinationFormPage extends StatelessWidget {
  const VaccinationFormPage({
    required this.householdId,
    required this.petId,
    required this.species,
    super.key,
    this.existing,
  });

  final String householdId;
  final String petId;
  final Species species;
  final Vaccination? existing;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VaccinationFormCubit>(
      create: (_) => sl<VaccinationFormCubit>(),
      child: _VaccinationFormView(
        householdId: householdId,
        petId: petId,
        species: species,
        existing: existing,
      ),
    );
  }
}

class _VaccinationFormView extends StatefulWidget {
  const _VaccinationFormView({
    required this.householdId,
    required this.petId,
    required this.species,
    this.existing,
  });

  final String householdId;
  final String petId;
  final Species species;
  final Vaccination? existing;

  @override
  State<_VaccinationFormView> createState() => _VaccinationFormViewState();
}

class _VaccinationFormViewState extends State<_VaccinationFormView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _vetCtrl = TextEditingController();
  final _clinicCtrl = TextEditingController();
  final _batchCtrl = TextEditingController();
  final _manufacturerCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  VaccineCategory _category = VaccineCategory.core;
  DateTime _appliedDate = DateTime.now().toUtc();
  DateTime? _nextDueDate;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e == null) return;
    _nameCtrl.text = e.name;
    _vetCtrl.text = e.vetName ?? '';
    _clinicCtrl.text = e.clinicName ?? '';
    _batchCtrl.text = e.batchNumber ?? '';
    _manufacturerCtrl.text = e.manufacturer ?? '';
    _notesCtrl.text = e.notes ?? '';
    _category = e.category;
    _appliedDate = e.appliedDate;
    _nextDueDate = e.nextDueDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _vetCtrl.dispose();
    _clinicCtrl.dispose();
    _batchCtrl.dispose();
    _manufacturerCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat.yMMMd();
    final presets = VaccinePresets.forSpecies(widget.species);

    return BlocConsumer<VaccinationFormCubit, VaccinationFormState>(
      listener: (context, state) {
        if (state is VaccinationFormSuccess) {
          context.pop();
        } else if (state is VaccinationFormError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(t.vaccinations.form.errors.saveFailed)),
            );
        }
      },
      builder: (context, state) {
        final submitting = state is VaccinationFormSubmitting;
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
                          onDelete: _isEdit && !submitting
                              ? () => _confirmDelete(context)
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (presets.isNotEmpty) ...[
                          _PresetChips(
                            presets: presets,
                            onPick: _applyPreset,
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        AppField(
                          icon: PhosphorIconsBold.syringe,
                          label: t.vaccinations.form.name,
                          child: TextFormField(
                            controller: _nameCtrl,
                            decoration: _bare(
                              t.vaccinations.form.namePlaceholder,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? t.common.required
                                : null,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppField(
                          icon: PhosphorIconsBold.tag,
                          label: t.vaccinations.form.category,
                          child: DropdownButtonFormField<VaccineCategory>(
                            initialValue: _category,
                            decoration: _bare(null),
                            isExpanded: true,
                            items: VaccineCategory.values
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child:
                                          Text(VaccineCategoryMeta.label(c)),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _category = v ?? _category),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AppField(
                                icon: PhosphorIconsBold.calendarBlank,
                                label: t.vaccinations.form.appliedDate,
                                child: _DateInline(
                                  value: _appliedDate,
                                  formatter: dateFmt,
                                  nullable: false,
                                  onPick: (d) => setState(
                                    () => _appliedDate = d ?? _appliedDate,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: AppField(
                                icon: PhosphorIconsBold.calendarPlus,
                                label: t.vaccinations.form.nextDueDate,
                                child: _DateInline(
                                  value: _nextDueDate,
                                  formatter: dateFmt,
                                  nullable: true,
                                  onPick: (d) =>
                                      setState(() => _nextDueDate = d),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppField(
                          icon: PhosphorIconsBold.stethoscope,
                          label: t.vaccinations.form.vetName,
                          child: TextFormField(
                            controller: _vetCtrl,
                            decoration: _bare(
                              t.vaccinations.form.vetPlaceholder,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppField(
                          icon: PhosphorIconsBold.house,
                          label: t.vaccinations.form.clinicName,
                          child: TextFormField(
                            controller: _clinicCtrl,
                            decoration: _bare(
                              t.vaccinations.form.clinicPlaceholder,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppField(
                          icon: PhosphorIconsBold.barcode,
                          label: t.vaccinations.form.batchNumber,
                          child: TextFormField(
                            controller: _batchCtrl,
                            decoration: _bare(
                              t.vaccinations.form.batchPlaceholder,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppField(
                          icon: PhosphorIconsBold.factory,
                          label: t.vaccinations.form.manufacturer,
                          child: TextFormField(
                            controller: _manufacturerCtrl,
                            decoration: _bare(
                              t.vaccinations.form.manufacturerPlaceholder,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppField(
                          icon: PhosphorIconsBold.notePencil,
                          label: t.vaccinations.form.notesOptional,
                          child: TextFormField(
                            controller: _notesCtrl,
                            decoration: _bare(
                              t.vaccinations.form.notesPlaceholder,
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
                      label: t.vaccinations.form.save,
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

  InputDecoration _bare(String? hint) {
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

  void _applyPreset(VaccinePreset p) {
    setState(() {
      _nameCtrl.text = p.name;
      _category = p.category;
      _nextDueDate = _appliedDate.add(
        Duration(days: p.defaultBoosterIntervalDays),
      );
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthBloc>().state;
    final user = switch (auth) {
      AuthAuthenticated(:final user) => user,
      AuthNeedsHousehold(:final user) => user,
      _ => null,
    };
    if (user == null) return;

    final now = DateTime.now().toUtc();
    final draft = Vaccination(
      id: widget.existing?.id ?? const Uuid().v4(),
      householdId: widget.householdId,
      petId: widget.petId,
      name: _nameCtrl.text.trim(),
      category: _category,
      appliedDate: _appliedDate,
      nextDueDate: _nextDueDate,
      vetName: _vetCtrl.text.trim().isEmpty ? null : _vetCtrl.text.trim(),
      clinicName:
          _clinicCtrl.text.trim().isEmpty ? null : _clinicCtrl.text.trim(),
      batchNumber:
          _batchCtrl.text.trim().isEmpty ? null : _batchCtrl.text.trim(),
      manufacturer: _manufacturerCtrl.text.trim().isEmpty
          ? null
          : _manufacturerCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      attachmentUrls: widget.existing?.attachmentUrls ?? const <String>[],
      reminderId: widget.existing?.reminderId,
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
      createdBy: widget.existing?.createdBy ?? user.uid,
    );

    final cubit = context.read<VaccinationFormCubit>();
    (_isEdit ? cubit.update(draft) : cubit.create(draft)).ignore();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.vaccinations.form.deleteConfirmTitle),
        content: Text(
          t.vaccinations.form.deleteConfirmMessage(petName: ''),
        ),
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
    if (confirmed != true) return;
    if (!context.mounted) return;
    if (widget.existing == null) return;
    context.read<VaccinationFormCubit>().delete(widget.existing!).ignore();
  }
}

class _FormHeader extends StatelessWidget {
  const _FormHeader({required this.isEdit, this.onDelete});

  final bool isEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final delete = onDelete;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleIconButton(
              icon: PhosphorIconsBold.arrowLeft,
              onTap: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                isEdit
                    ? t.vaccinations.form.editTitle
                    : t.vaccinations.form.createTitle,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (delete != null)
              CircleIconButton(
                icon: PhosphorIconsBold.trash,
                onTap: delete,
                tooltip: t.vaccinations.form.delete,
                foregroundColor: theme.colorScheme.error,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          isEdit
              ? t.vaccinations.form.editSubtitle
              : t.vaccinations.form.createSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: context.palette.onSurfaceMuted,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _PresetChips extends StatelessWidget {
  const _PresetChips({required this.presets, required this.onPick});

  final List<VaccinePreset> presets;
  final ValueChanged<VaccinePreset> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.vaccinations.form.presetSection,
          style: theme.textTheme.titleSmall?.copyWith(
            color: context.palette.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: presets
              .map((p) => _PresetChip(
                    label: p.name,
                    onTap: () => onPick(p),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primaryContainer,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.brPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.brPill,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs + 2,
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
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
    required this.nullable,
  });

  final DateTime? value;
  final DateFormat formatter;
  final ValueChanged<DateTime?> onPick;
  final bool nullable;

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
          firstDate: DateTime(now.year - 30),
          lastDate: DateTime(now.year + 10),
        );
        if (picked != null) onPick(picked);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value == null
                    ? t.pets.form.selectDate
                    : formatter.format(value!),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: value == null ? palette.onSurfaceFaint : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (nullable && value != null)
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
