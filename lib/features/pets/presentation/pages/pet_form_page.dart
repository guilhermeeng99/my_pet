import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:my_pet/app/di/injection_container.dart';
import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:my_pet/features/pets/domain/entities/pet.dart';
import 'package:my_pet/features/pets/domain/entities/sex.dart';
import 'package:my_pet/features/pets/domain/entities/species.dart';
import 'package:my_pet/features/pets/presentation/cubit/pet_form_cubit.dart';
import 'package:my_pet/features/pets/presentation/widgets/species_meta.dart';
import 'package:my_pet/gen/strings.g.dart';
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

  Species _species = Species.cat;
  Sex _sex = Sex.unknown;
  bool _neutered = false;
  DateTime? _birthDate;
  DateTime? _adoptionDate;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
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
          appBar: AppBar(
            title: Text(_isEdit ? t.pets.form.editTitle : t.pets.form.createTitle),
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: t.pets.form.name,
                      hintText: t.pets.form.namePlaceholder,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? t.pets.form.errors.nameRequired
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<Species>(
                    initialValue: _species,
                    decoration: InputDecoration(labelText: t.pets.form.species),
                    items: Species.values
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(SpeciesMeta.label(s)),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _species = v ?? _species),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _breedCtrl,
                    decoration: InputDecoration(labelText: t.pets.form.breed),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<Sex>(
                    initialValue: _sex,
                    decoration: InputDecoration(labelText: t.pets.form.sex),
                    items: Sex.values
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(SexMeta.label(s)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _sex = v ?? _sex),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SwitchListTile(
                    title: Text(t.pets.form.neutered),
                    value: _neutered,
                    onChanged: (v) => setState(() => _neutered = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _DateField(
                    label: t.pets.form.birthDate,
                    value: _birthDate,
                    formatter: dateFmt,
                    onPick: (d) => setState(() => _birthDate = d),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _DateField(
                    label: t.pets.form.adoptionDate,
                    value: _adoptionDate,
                    formatter: dateFmt,
                    onPick: (d) => setState(() => _adoptionDate = d),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _colorCtrl,
                    decoration: InputDecoration(labelText: t.pets.form.color),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _microchipCtrl,
                    decoration:
                        InputDecoration(labelText: t.pets.form.microchipId),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _notesCtrl,
                    decoration: InputDecoration(labelText: t.pets.form.notes),
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
                        : Text(t.pets.form.save),
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
    if (user == null || user.householdId == null) return;

    final now = DateTime.now().toUtc();
    final draft = Pet(
      id: widget.existing?.id ?? const Uuid().v4(),
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
      photoUrl: widget.existing?.photoUrl,
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

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.formatter,
    required this.onPick,
  });

  final String label;
  final DateTime? value;
  final DateFormat formatter;
  final ValueChanged<DateTime?> onPick;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value == null ? t.pets.form.selectDate : formatter.format(value!),
            ),
          ),
          if (value != null)
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
                lastDate: now,
              );
              if (picked != null) onPick(picked);
            },
          ),
        ],
      ),
    );
  }
}
