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
import 'package:my_pet/features/pets/domain/entities/pet.dart';
import 'package:my_pet/features/pets/domain/repositories/pet_repository.dart';
import 'package:my_pet/features/reminders/domain/entities/recurrence.dart';
import 'package:my_pet/features/reminders/domain/entities/reminder.dart';
import 'package:my_pet/features/reminders/domain/entities/reminder_type.dart';
import 'package:my_pet/features/reminders/presentation/cubit/reminder_form_cubit.dart';
import 'package:my_pet/features/reminders/presentation/cubit/reminder_form_state.dart';
import 'package:my_pet/features/reminders/presentation/widgets/recurrence_meta.dart';
import 'package:my_pet/features/reminders/presentation/widgets/reminder_type_meta.dart';
import 'package:my_pet/gen/strings.g.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ReminderFormPage extends StatelessWidget {
  const ReminderFormPage({super.key, this.existing});

  final Reminder? existing;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReminderFormCubit>(
      create: (_) => sl<ReminderFormCubit>(),
      child: _ReminderFormView(existing: existing),
    );
  }
}

class _ReminderFormView extends StatefulWidget {
  const _ReminderFormView({this.existing});
  final Reminder? existing;

  @override
  State<_ReminderFormView> createState() => _ReminderFormViewState();
}

class _ReminderFormViewState extends State<_ReminderFormView> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _customIntervalCtrl = TextEditingController();

  ReminderType _type = ReminderType.custom;
  Recurrence _recurrence = Recurrence.oneShot;
  DateTime _dueAt = DateTime.now().add(const Duration(hours: 1));
  String? _petId;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e == null) return;
    _titleCtrl.text = e.title;
    _descCtrl.text = e.description ?? '';
    _type = e.type;
    _recurrence = e.recurrence;
    _dueAt = e.dueAt.toLocal();
    _petId = e.petId;
    if (e.recurrenceIntervalDays != null) {
      _customIntervalCtrl.text = e.recurrenceIntervalDays!.toString();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _customIntervalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final dateFmt = DateFormat.yMMMd().add_jm();
    return BlocConsumer<ReminderFormCubit, ReminderFormState>(
      listener: (context, state) {
        if (state is ReminderFormSuccess) {
          context.pop();
        } else if (state is ReminderFormError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(t.reminders.errors.saveFailed)),
            );
        }
      },
      builder: (context, state) {
        final submitting = state is ReminderFormSubmitting;
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
                              ? t.reminders.form.editTitle
                              : t.reminders.form.createTitle,
                          style: theme.textTheme.headlineLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _isEdit
                              ? t.reminders.form.editSubtitle
                              : t.reminders.form.createSubtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: palette.onSurfaceMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppField(
                          icon: PhosphorIconsBold.bell,
                          label: t.reminders.form.titleLabel,
                          child: TextFormField(
                            controller: _titleCtrl,
                            decoration: _bare(t.reminders.form.titlePlaceholder),
                            maxLength: 80,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return t.reminders.form.errors.titleRequired;
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _SectionLabel(t.reminders.form.type),
                        const SizedBox(height: AppSpacing.xs),
                        _TypeChipRow(
                          current: _type,
                          onChanged: (t) {
                            setState(() {
                              _type = t;
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppField(
                          icon: PhosphorIconsBold.calendarBlank,
                          label: t.reminders.form.dueAt,
                          child: InkWell(
                            onTap: _pickDateTime,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      dateFmt.format(_dueAt),
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
                        const SizedBox(height: AppSpacing.sm),
                        _SectionLabel(t.reminders.form.recurrence),
                        const SizedBox(height: AppSpacing.xs),
                        _RecurrenceChipRow(
                          current: _recurrence,
                          onChanged: (r) => setState(() => _recurrence = r),
                        ),
                        if (_recurrence == Recurrence.custom) ...[
                          const SizedBox(height: AppSpacing.sm),
                          AppField(
                            icon: PhosphorIconsBold.arrowsClockwise,
                            label: t.reminders.form.customIntervalLabel,
                            child: TextFormField(
                              controller: _customIntervalCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _bare(
                                t.reminders.form.customIntervalPlaceholder,
                              ),
                              validator: (v) {
                                if (_recurrence != Recurrence.custom) {
                                  return null;
                                }
                                final n = int.tryParse((v ?? '').trim());
                                if (n == null || n <= 0) {
                                  return t.reminders.form.errors.intervalInvalid;
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        AppField(
                          icon: PhosphorIconsBold.notePencil,
                          label: t.reminders.form.descriptionOptional,
                          child: TextFormField(
                            controller: _descCtrl,
                            decoration: _bare(
                              t.reminders.form.descriptionPlaceholder,
                            ),
                            maxLines: 3,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _SectionLabel(t.reminders.form.petOptional),
                        const SizedBox(height: AppSpacing.xs),
                        _PetPicker(
                          selectedId: _petId,
                          onChanged: (id) => setState(() => _petId = id),
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
                      label: t.reminders.form.save,
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
        counterText: '',
      );

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final initialDate = _dueAt.isBefore(now) ? now : _dueAt;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueAt),
    );
    if (pickedTime == null || !mounted) return;
    setState(() {
      _dueAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthBloc>().state;
    final user = switch (auth) {
      AuthAuthenticated(:final user) => user,
      _ => null,
    };
    if (user == null || user.householdId == null) return;

    final now = DateTime.now().toUtc();
    final existing = widget.existing;
    final draft = Reminder(
      id: existing?.id ?? '',
      householdId: user.householdId!,
      petId: _petId,
      type: _type,
      title: _titleCtrl.text.trim(),
      description:
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      dueAt: _dueAt.toUtc(),
      notifyBeforeMinutes:
          existing?.notifyBeforeMinutes ?? _type.defaultNotifyBeforeMinutes,
      recurrence: _recurrence,
      recurrenceIntervalDays: _recurrence == Recurrence.custom
          ? int.tryParse(_customIntervalCtrl.text.trim())
          : null,
      done: existing?.done ?? false,
      doneAt: existing?.doneAt,
      sourceFeature: existing?.sourceFeature,
      createdAt: existing?.createdAt ?? now,
      createdBy: existing?.createdBy ?? user.uid,
    );

    final cubit = context.read<ReminderFormCubit>();
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

class _TypeChipRow extends StatelessWidget {
  const _TypeChipRow({required this.current, required this.onChanged});
  final ReminderType current;
  final ValueChanged<ReminderType> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final t in ReminderType.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: _ChoiceChip(
                label: ReminderTypeMeta.label(t),
                icon: ReminderTypeMeta.icon(t),
                selected: t == current,
                onTap: () => onChanged(t),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecurrenceChipRow extends StatelessWidget {
  const _RecurrenceChipRow({required this.current, required this.onChanged});
  final Recurrence current;
  final ValueChanged<Recurrence> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final r in Recurrence.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: _ChoiceChip(
                label: RecurrenceMeta.label(r),
                selected: r == current,
                onTap: () => onChanged(r),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

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
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: selected
                      ? theme.colorScheme.onPrimary
                      : palette.onSurfaceMuted,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
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

class _PetPicker extends StatefulWidget {
  const _PetPicker({required this.selectedId, required this.onChanged});
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  State<_PetPicker> createState() => _PetPickerState();
}

class _PetPickerState extends State<_PetPicker> {
  late final Stream<List<Pet>> _stream;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthBloc>().state;
    final householdId = switch (auth) {
      AuthAuthenticated(:final user) => user.householdId,
      _ => null,
    };
    _stream = householdId == null
        ? const Stream<List<Pet>>.empty()
        : sl<PetRepository>().watchActive(householdId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Pet>>(
      stream: _stream,
      builder: (context, snapshot) {
        final pets = snapshot.data ?? const <Pet>[];
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _ChoiceChip(
                label: t.reminders.form.allHousehold,
                selected: widget.selectedId == null,
                onTap: () => widget.onChanged(null),
              ),
              const SizedBox(width: AppSpacing.xs),
              for (final p in pets) ...[
                _ChoiceChip(
                  label: p.name,
                  selected: widget.selectedId == p.id,
                  onTap: () => widget.onChanged(p.id),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
            ],
          ),
        );
      },
    );
  }
}
