import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:my_pet/app/di/injection_container.dart';
import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/core/data/vaccine_presets.dart';
import 'package:my_pet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:my_pet/features/pets/domain/entities/species.dart';
import 'package:my_pet/features/vaccinations/domain/entities/vaccination.dart';
import 'package:my_pet/features/vaccinations/domain/entities/vaccine_category.dart';
import 'package:my_pet/features/vaccinations/presentation/cubit/vaccination_form_cubit.dart';
import 'package:my_pet/features/vaccinations/presentation/widgets/vaccination_meta.dart';
import 'package:my_pet/gen/strings.g.dart';
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
          appBar: AppBar(
            title: Text(_isEdit
                ? t.vaccinations.form.editTitle
                : t.vaccinations.form.createTitle),
            actions: [
              if (_isEdit)
                IconButton(
                  tooltip: t.vaccinations.form.delete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: submitting ? null : () => _confirmDelete(context),
                ),
            ],
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  if (presets.isNotEmpty) ...[
                    Text(
                      t.vaccinations.form.presetSection,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: presets
                          .map((p) => ActionChip(
                                label: Text(p.name),
                                tooltip: t.vaccinations.form.presetTooltip,
                                onPressed: () {
                                  setState(() {
                                    _nameCtrl.text = p.name;
                                    _category = p.category;
                                    _nextDueDate = _appliedDate.add(
                                      Duration(
                                        days: p.defaultBoosterIntervalDays,
                                      ),
                                    );
                                  });
                                },
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: t.vaccinations.form.name,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? t.common.required
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<VaccineCategory>(
                    initialValue: _category,
                    decoration: InputDecoration(
                      labelText: t.vaccinations.form.category,
                    ),
                    items: VaccineCategory.values
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(VaccineCategoryMeta.label(c)),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _category = v ?? _category),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _DateField(
                    label: t.vaccinations.form.appliedDate,
                    value: _appliedDate,
                    formatter: dateFmt,
                    onPick: (d) => setState(() => _appliedDate = d ?? _appliedDate),
                    nullable: false,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _DateField(
                    label: t.vaccinations.form.nextDueDate,
                    value: _nextDueDate,
                    formatter: dateFmt,
                    onPick: (d) => setState(() => _nextDueDate = d),
                    nullable: true,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _vetCtrl,
                    decoration: InputDecoration(
                      labelText: t.vaccinations.form.vetName,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _clinicCtrl,
                    decoration: InputDecoration(
                      labelText: t.vaccinations.form.clinicName,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _batchCtrl,
                    decoration: InputDecoration(
                      labelText: t.vaccinations.form.batchNumber,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _manufacturerCtrl,
                    decoration: InputDecoration(
                      labelText: t.vaccinations.form.manufacturer,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _notesCtrl,
                    decoration: InputDecoration(
                      labelText: t.vaccinations.form.notes,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    onPressed: submitting ? null : _submit,
                    child: submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(t.vaccinations.form.save),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.formatter,
    required this.onPick,
    required this.nullable,
  });

  final String label;
  final DateTime? value;
  final DateFormat formatter;
  final ValueChanged<DateTime?> onPick;
  final bool nullable;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value == null
                  ? t.pets.form.selectDate
                  : formatter.format(value!),
              style: TextStyle(
                color: value == null
                    ? context.palette.onSurfaceMuted
                    : null,
              ),
            ),
          ),
          if (nullable && value != null)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () => onPick(null),
            ),
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded),
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: value ?? now,
                firstDate: DateTime(now.year - 30),
                lastDate: DateTime(now.year + 10),
              );
              if (picked != null) onPick(picked);
            },
          ),
        ],
      ),
    );
  }
}
