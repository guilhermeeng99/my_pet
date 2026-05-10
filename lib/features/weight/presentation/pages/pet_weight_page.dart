import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_pet/app/di/injection_container.dart';
import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_radii.dart';
import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/app/widgets/app_card.dart';
import 'package:my_pet/app/widgets/app_primary_button.dart';
import 'package:my_pet/app/widgets/circle_icon_button.dart';
import 'package:my_pet/app/widgets/section_header.dart';
import 'package:my_pet/app/widgets/status_badge.dart';
import 'package:my_pet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:my_pet/features/weight/domain/entities/weight_entry.dart';
import 'package:my_pet/features/weight/domain/entities/weight_stats.dart';
import 'package:my_pet/features/weight/presentation/cubit/weight_form_cubit.dart';
import 'package:my_pet/features/weight/presentation/cubit/weight_form_state.dart';
import 'package:my_pet/features/weight/presentation/cubit/weight_history_cubit.dart';
import 'package:my_pet/features/weight/presentation/cubit/weight_history_state.dart';
import 'package:my_pet/features/weight/presentation/widgets/weight_sparkline.dart';
import 'package:my_pet/gen/strings.g.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Args bundle for the weight route. Pet name is included so the form
/// title can say "{name} weigh-in" without an extra Firestore read.
class PetWeightArgs {
  const PetWeightArgs({
    required this.householdId,
    required this.petId,
    required this.petName,
  });

  final String householdId;
  final String petId;
  final String petName;
}

/// Weight history + chart for a single pet. Bottom-sheet form for new
/// weigh-ins keeps the flow on a single screen.
class PetWeightPage extends StatelessWidget {
  const PetWeightPage({
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
    return BlocProvider<WeightHistoryCubit>(
      create: (_) => WeightHistoryCubit(repository: sl())
        ..start(householdId, petId),
      child: _WeightView(
        householdId: householdId,
        petId: petId,
        petName: petName,
      ),
    );
  }
}

class _WeightView extends StatelessWidget {
  const _WeightView({
    required this.householdId,
    required this.petId,
    required this.petName,
  });

  final String householdId;
  final String petId;
  final String petName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  CircleIconButton(
                    icon: PhosphorIconsBold.arrowLeft,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      t.weight.tabTitle,
                      style: theme.textTheme.headlineLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: BlocBuilder<WeightHistoryCubit, WeightHistoryState>(
                  builder: (context, state) {
                    return switch (state) {
                      WeightHistoryInitial() || WeightHistoryLoading() =>
                        const Center(child: CircularProgressIndicator()),
                      WeightHistoryEmpty() => _Empty(
                          onAdd: () => _openForm(context),
                        ),
                      WeightHistoryLoaded() => _Loaded(state: state),
                      WeightHistoryError() => Center(
                          child: Text(t.weight.errors.loadFailed),
                        ),
                    };
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(PhosphorIconsBold.plus),
        label: Text(t.weight.addWeight),
      ),
    );
  }

  Future<void> _openForm(BuildContext context) async {
    final cubit = context.read<WeightHistoryCubit>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return BlocProvider<WeightFormCubit>(
          create: (_) => sl<WeightFormCubit>(),
          child: BlocProvider.value(
            value: cubit,
            child: _WeightFormSheet(
              householdId: householdId,
              petId: petId,
              petName: petName,
            ),
          ),
        );
      },
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
        Icon(
          PhosphorIconsBold.scales,
          size: 64,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          t.weight.empty.title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          t.weight.empty.subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: palette.onSurfaceMuted),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppPrimaryButton(
          label: t.weight.addWeight,
          icon: PhosphorIconsBold.plus,
          onPressed: onAdd,
        ),
      ],
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.state});
  final WeightHistoryLoaded state;

  @override
  Widget build(BuildContext context) {
    final stats = state.stats;
    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        if (stats.hasDanger || stats.hasWarning) _AlertBanner(stats: stats),
        const SizedBox(height: AppSpacing.sm),
        WeightSparkline(entries: state.entries),
        const SizedBox(height: AppSpacing.md),
        _StatsRow(stats: stats),
        const SizedBox(height: AppSpacing.lg),
        SectionHeader(title: t.weight.historySection),
        const SizedBox(height: AppSpacing.sm),
        for (final entry in state.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _EntryTile(entry: entry),
          ),
      ],
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.stats});
  final WeightStats stats;

  @override
  Widget build(BuildContext context) {
    final pct = stats.change30dPercent ?? 0;
    final pctLabel =
        '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%';
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: AppCard(
        child: Row(
          children: [
            StatusBadge(
              label: pctLabel,
              tone: stats.hasDanger ? StatusTone.danger : StatusTone.warning,
              icon: PhosphorIconsBold.trendUp,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                stats.hasDanger
                    ? t.weight.alerts.danger
                    : t.weight.alerts.warning,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});
  final WeightStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCell(
            label: t.weight.stats.latest,
            value: _fmt(stats.latest?.weightKg),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCell(
            label: t.weight.stats.thirtyDays,
            value: _fmtPct(stats.change30dPercent),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCell(
            label: t.weight.stats.average,
            value: _fmt(stats.avg),
          ),
        ),
      ],
    );
  }

  String _fmt(double? v) => v == null ? '—' : '${v.toStringAsFixed(2)} kg';
  String _fmtPct(double? v) {
    if (v == null) return '—';
    return '${v >= 0 ? '+' : ''}${v.toStringAsFixed(1)}%';
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: context.palette.outline, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.palette.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});
  final WeightEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final dateFmt = DateFormat.yMMMd();
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: AppRadii.brMd,
            ),
            child: Icon(
              PhosphorIconsBold.scales,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${entry.weightKg.toStringAsFixed(2)} kg',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  dateFmt.format(entry.date.toLocal()),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: palette.onSurfaceMuted),
                ),
                if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.notes!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: palette.onSurfaceFaint),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => _confirmDelete(context, entry),
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

  Future<void> _confirmDelete(BuildContext context, WeightEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.weight.deleteConfirmTitle),
        content: Text(t.weight.deleteConfirmMessage),
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
    await context.read<WeightHistoryCubit>().delete(
          entry.householdId,
          entry.petId,
          entry.id,
        );
  }
}

class _WeightFormSheet extends StatefulWidget {
  const _WeightFormSheet({
    required this.householdId,
    required this.petId,
    required this.petName,
  });

  final String householdId;
  final String petId;
  final String petName;

  @override
  State<_WeightFormSheet> createState() => _WeightFormSheetState();
}

class _WeightFormSheetState extends State<_WeightFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _weightCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _weightCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final dateFmt = DateFormat.yMMMd();
    return BlocConsumer<WeightFormCubit, WeightFormState>(
      listener: (context, state) {
        if (state is WeightFormSuccess) {
          Navigator.of(context).pop();
        } else if (state is WeightFormError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(t.weight.errors.saveFailed)),
            );
        }
      },
      builder: (context, state) {
        final submitting = state is WeightFormSubmitting;
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
                  t.weight.form.title(petName: widget.petName),
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _weightCtrl,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: t.weight.form.weightKg,
                    prefixIcon: const Icon(PhosphorIconsBold.scales),
                    suffixText: 'kg',
                  ),
                  validator: (v) {
                    final raw = (v ?? '').trim().replaceAll(',', '.');
                    final n = double.tryParse(raw);
                    if (n == null || n <= 0 || n > 200) {
                      return t.weight.form.errors.invalidWeight;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(DateTime.now().year - 30),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: t.weight.form.date,
                      prefixIcon: const Icon(PhosphorIconsBold.calendarBlank),
                    ),
                    child: Text(dateFmt.format(_date)),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: InputDecoration(
                    labelText: t.weight.form.notesOptional,
                    prefixIcon: const Icon(PhosphorIconsBold.notePencil),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.md),
                AppPrimaryButton(
                  label: t.weight.form.save,
                  loading: submitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthBloc>().state;
    final uid = switch (auth) {
      AuthAuthenticated(:final user) => user.uid,
      _ => '',
    };
    final weight = double.parse(
      _weightCtrl.text.trim().replaceAll(',', '.'),
    );
    final notes =
        _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();
    final now = DateTime.now().toUtc();
    final draft = WeightEntry(
      id: '',
      householdId: widget.householdId,
      petId: widget.petId,
      date: DateTime.utc(_date.year, _date.month, _date.day),
      weightKg: weight,
      notes: notes,
      createdAt: now,
      createdBy: uid,
    );
    context.read<WeightFormCubit>().create(draft).ignore();
  }
}
