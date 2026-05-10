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
import 'package:my_pet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:my_pet/features/health/domain/entities/health_event.dart';
import 'package:my_pet/features/health/domain/entities/health_event_type.dart';
import 'package:my_pet/features/health/domain/entities/medication_details.dart';
import 'package:my_pet/features/health/presentation/cubit/health_form_cubit.dart';
import 'package:my_pet/features/health/presentation/cubit/health_form_state.dart';
import 'package:my_pet/features/health/presentation/widgets/health_event_type_meta.dart';
import 'package:my_pet/gen/strings.g.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Create/edit form. Type chips at top control which optional sections
/// appear: clinic + vet for visits/exams, medication sub-form for meds.
class HealthEventFormPage extends StatelessWidget {
  const HealthEventFormPage({
    required this.householdId,
    required this.petId,
    required this.petName,
    this.existing,
    super.key,
  });

  final String householdId;
  final String petId;
  final String petName;
  final HealthEvent? existing;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HealthFormCubit>(
      create: (_) => sl<HealthFormCubit>(),
      child: _FormView(
        householdId: householdId,
        petId: petId,
        existing: existing,
      ),
    );
  }
}

class _FormView extends StatefulWidget {
  const _FormView({
    required this.householdId,
    required this.petId,
    this.existing,
  });

  final String householdId;
  final String petId;
  final HealthEvent? existing;

  @override
  State<_FormView> createState() => _FormViewState();
}

class _FormViewState extends State<_FormView> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _vetCtrl = TextEditingController();
  final _clinicCtrl = TextEditingController();
  final _costCtrl = TextEditingController();

  // Medication-only fields.
  final _medNameCtrl = TextEditingController();
  final _medDosageCtrl = TextEditingController();
  final _medFreqCtrl = TextEditingController();
  final _medDurationCtrl = TextEditingController();
  final _medPrescribedByCtrl = TextEditingController();

  HealthEventType _type = HealthEventType.vetVisit;
  DateTime _date = DateTime.now();

  bool get _isEdit => widget.existing != null;
  bool get _showVet =>
      _type == HealthEventType.vetVisit ||
      _type == HealthEventType.exam ||
      _type == HealthEventType.symptom;
  bool get _showMedication => _type == HealthEventType.medication;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e == null) return;
    _type = e.type;
    _titleCtrl.text = e.title;
    _descCtrl.text = e.description ?? '';
    _vetCtrl.text = e.vetName ?? '';
    _clinicCtrl.text = e.clinicName ?? '';
    _date = e.date.toLocal();
    if (e.cost != null) _costCtrl.text = e.cost!.toStringAsFixed(2);
    final med = e.medication;
    if (med != null) {
      _medNameCtrl.text = med.name;
      _medDosageCtrl.text = med.dosage;
      _medFreqCtrl.text = med.frequency;
      _medDurationCtrl.text = med.durationDays.toString();
      _medPrescribedByCtrl.text = med.prescribedBy ?? '';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _vetCtrl.dispose();
    _clinicCtrl.dispose();
    _costCtrl.dispose();
    _medNameCtrl.dispose();
    _medDosageCtrl.dispose();
    _medFreqCtrl.dispose();
    _medDurationCtrl.dispose();
    _medPrescribedByCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final dateFmt = DateFormat.yMMMd();
    return BlocConsumer<HealthFormCubit, HealthFormState>(
      listener: (context, state) {
        if (state is HealthFormSuccess) {
          context.pop();
        } else if (state is HealthFormError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(t.health.errors.saveFailed)),
            );
        }
      },
      builder: (context, state) {
        final submitting = state is HealthFormSubmitting;
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
                        CircleIconButton(
                          icon: PhosphorIconsBold.arrowLeft,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _isEdit
                              ? t.health.form.editTitle
                              : t.health.form.createTitle,
                          style: theme.textTheme.headlineLarge,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _SectionLabel(t.health.form.type),
                        const SizedBox(height: AppSpacing.xs),
                        _TypeChips(
                          current: _type,
                          onChanged: (t) => setState(() => _type = t),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppField(
                          icon: PhosphorIconsBold.notePencil,
                          label: t.health.form.titleLabel,
                          child: TextFormField(
                            controller: _titleCtrl,
                            decoration:
                                _bare(t.health.form.titlePlaceholder),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return t.health.form.errors.titleRequired;
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppField(
                          icon: PhosphorIconsBold.calendarBlank,
                          label: t.health.form.date,
                          child: InkWell(
                            onTap: _pickDate,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      dateFmt.format(_date),
                                      style: theme.textTheme.bodyLarge,
                                    ),
                                  ),
                                  Icon(
                                    PhosphorIconsRegular.caretDown,
                                    size: 16,
                                    color: palette.onSurfaceFaint,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_showVet) ...[
                          const SizedBox(height: AppSpacing.sm),
                          AppField(
                            icon: PhosphorIconsBold.stethoscope,
                            label: t.health.form.vetName,
                            child: TextFormField(
                              controller: _vetCtrl,
                              decoration: _bare(t.common.optional),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppField(
                            icon: PhosphorIconsBold.buildings,
                            label: t.health.form.clinicName,
                            child: TextFormField(
                              controller: _clinicCtrl,
                              decoration: _bare(t.common.optional),
                            ),
                          ),
                        ],
                        if (_showMedication) ...[
                          const SizedBox(height: AppSpacing.sm),
                          AppField(
                            icon: PhosphorIconsBold.pill,
                            label: t.health.form.medication.name,
                            child: TextFormField(
                              controller: _medNameCtrl,
                              decoration: _bare(null),
                              validator: _requiredIfMedication,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppField(
                            icon: PhosphorIconsBold.eyedropper,
                            label: t.health.form.medication.dosage,
                            child: TextFormField(
                              controller: _medDosageCtrl,
                              decoration:
                                  _bare(t.health.form.medication.dosageHint),
                              validator: _requiredIfMedication,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppField(
                            icon: PhosphorIconsBold.clock,
                            label: t.health.form.medication.frequency,
                            child: TextFormField(
                              controller: _medFreqCtrl,
                              decoration: _bare(
                                t.health.form.medication.frequencyHint,
                              ),
                              validator: _requiredIfMedication,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppField(
                            icon: PhosphorIconsBold.calendar,
                            label: t.health.form.medication.durationDays,
                            child: TextFormField(
                              controller: _medDurationCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _bare('7'),
                              validator: (v) {
                                if (!_showMedication) return null;
                                final n = int.tryParse((v ?? '').trim());
                                if (n == null || n <= 0) {
                                  return t.health.form.errors.invalidDuration;
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppField(
                            icon: PhosphorIconsBold.userCircle,
                            label: t.health.form.medication.prescribedBy,
                            child: TextFormField(
                              controller: _medPrescribedByCtrl,
                              decoration: _bare(t.common.optional),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        AppField(
                          icon: PhosphorIconsBold.notePencil,
                          label: t.health.form.descriptionOptional,
                          child: TextFormField(
                            controller: _descCtrl,
                            decoration:
                                _bare(t.health.form.descriptionPlaceholder),
                            maxLines: 3,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppField(
                          icon: PhosphorIconsBold.coins,
                          label: t.health.form.costOptional,
                          child: TextFormField(
                            controller: _costCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _bare('0.00'),
                            validator: (v) {
                              final raw =
                                  (v ?? '').trim().replaceAll(',', '.');
                              if (raw.isEmpty) return null;
                              final n = double.tryParse(raw);
                              if (n == null || n < 0) {
                                return t.health.form.errors.invalidCost;
                              }
                              return null;
                            },
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
                      label: t.health.form.save,
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

  String? _requiredIfMedication(String? v) {
    if (!_showMedication) return null;
    if (v == null || v.trim().isEmpty) return t.common.required;
    return null;
  }

  InputDecoration _bare(String? hint) => InputDecoration(
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(DateTime.now().year - 10),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthBloc>().state;
    final uid = switch (auth) {
      AuthAuthenticated(:final user) => user.uid,
      _ => '',
    };

    MedicationDetails? med;
    if (_showMedication) {
      med = MedicationDetails(
        name: _medNameCtrl.text.trim(),
        dosage: _medDosageCtrl.text.trim(),
        frequency: _medFreqCtrl.text.trim(),
        durationDays: int.parse(_medDurationCtrl.text.trim()),
        prescribedBy: _medPrescribedByCtrl.text.trim().isEmpty
            ? null
            : _medPrescribedByCtrl.text.trim(),
      );
    }

    final costRaw = _costCtrl.text.trim().replaceAll(',', '.');
    final cost = costRaw.isEmpty ? null : double.tryParse(costRaw);

    final endDate = med == null
        ? null
        : _date.add(Duration(days: med.durationDays));
    final now = DateTime.now().toUtc();
    final existing = widget.existing;
    final draft = HealthEvent(
      id: existing?.id ?? '',
      householdId: widget.householdId,
      petId: widget.petId,
      type: _type,
      title: _titleCtrl.text.trim(),
      date: DateTime.utc(_date.year, _date.month, _date.day),
      endDate: endDate?.toUtc(),
      description:
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      vetName: _showVet && _vetCtrl.text.trim().isNotEmpty
          ? _vetCtrl.text.trim()
          : null,
      clinicName: _showVet && _clinicCtrl.text.trim().isNotEmpty
          ? _clinicCtrl.text.trim()
          : null,
      medication: med,
      cost: cost,
      attachmentUrls: existing?.attachmentUrls ?? const <String>[],
      reminderIds: existing?.reminderIds ?? const <String>[],
      createdAt: existing?.createdAt ?? now,
      createdBy: existing?.createdBy ?? uid,
    );
    final cubit = context.read<HealthFormCubit>();
    (_isEdit ? cubit.update(draft) : cubit.create(draft)).ignore();
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelLarge?.copyWith(
        color: context.palette.onSurfaceMuted,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _TypeChips extends StatelessWidget {
  const _TypeChips({required this.current, required this.onChanged});
  final HealthEventType current;
  final ValueChanged<HealthEventType> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final t in HealthEventType.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: _Chip(
                label: HealthEventTypeMeta.label(t),
                icon: HealthEventTypeMeta.icon(t),
                selected: t == current,
                onTap: () => onChanged(t),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return Material(
      color: selected
          ? theme.colorScheme.primary
          : palette.surfaceMuted,
      borderRadius: AppRadii.brPill,
      child: InkWell(
        borderRadius: AppRadii.brPill,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? theme.colorScheme.onPrimary
                    : palette.onSurfaceMuted,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: selected
                      ? theme.colorScheme.onPrimary
                      : palette.onSurfaceMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
