import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/training_block/bloc/training_block_bloc.dart';
import 'package:flutter_application_1/features/training_block/data/models/training_block_model.dart';
import 'package:intl/intl.dart';

/// Section embedded in the trainer's athlete-detail screen. Lists training
/// blocks for the athlete and provides create / edit / delete via a bottom
/// sheet form.
class TrainingBlocksSection extends StatefulWidget {
  final String athleteId;
  const TrainingBlocksSection({super.key, required this.athleteId});

  @override
  State<TrainingBlocksSection> createState() => _TrainingBlocksSectionState();
}

class _TrainingBlocksSectionState extends State<TrainingBlocksSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<TrainingBlockBloc>()
          .add(LoadTrainingBlocks(widget.athleteId));
    });
  }

  void _openForm({TrainingBlockModel? existing}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DT.gbWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DT.rCard)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: BlocProvider.value(
          value: context.read<TrainingBlockBloc>(),
          child: _TrainingBlockForm(
            athleteId: widget.athleteId,
            existing: existing,
          ),
        ),
      ),
    );
  }

  void _confirmDelete(TrainingBlockModel b) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Blokk törlése'),
        content: Text(
            'Biztosan törlöd a(z) "${b.focus}" blokkot (${_fmt(b.startDate)} – ${_fmt(b.endDate)})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mégse'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TrainingBlockBloc>().add(DeleteTrainingBlock(
                    id: b.id,
                    athleteId: widget.athleteId,
                  ));
            },
            child: const Text('Törlés',
                style: TextStyle(color: DT.cardRed)),
          ),
        ],
      ),
    );
  }

  static String _fmt(DateTime d) =>
      DateFormat('yyyy.MM.dd').format(d.toLocal());

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TrainingBlockBloc, TrainingBlockState>(
      listenWhen: (prev, curr) =>
          curr is TrainingBlockOverlap ||
          curr is TrainingBlockForbidden ||
          curr is TrainingBlockError,
      listener: (context, state) {
        if (state is TrainingBlockOverlap) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: DT.cardOrange,
          ));
        } else if (state is TrainingBlockForbidden) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Not authorized'),
            backgroundColor: DT.cardRed,
          ));
        } else if (state is TrainingBlockError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: DT.cardRed,
          ));
        }
      },
      buildWhen: (prev, curr) =>
          curr is TrainingBlocksLoaded ||
          curr is TrainingBlockLoading ||
          curr is TrainingBlockInitial ||
          curr is TrainingBlockForbidden,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Tréningblokkok',
                  style: TextStyle(
                    fontSize: DT.s4,
                    fontWeight: FontWeight.w700,
                    color: DT.of(context).textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Új'),
                  style: TextButton.styleFrom(
                    foregroundColor: DT.metricBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DT.s2),
            if (state is TrainingBlockLoading || state is TrainingBlockInitial)
              const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state is TrainingBlockForbidden)
              _emptyCard(context, 'Not authorized')
            else if (state is TrainingBlocksLoaded)
              state.blocks.isEmpty
                  ? _emptyCard(
                      context, 'Nincs még tréningblokk ehhez a sportolóhoz.')
                  : Column(
                      children: state.blocks
                          .map((b) => _BlockRow(
                                block: b,
                                onEdit: () => _openForm(existing: b),
                                onDelete: () => _confirmDelete(b),
                              ))
                          .toList(),
                    ),
          ],
        );
      },
    );
  }

  Widget _emptyCard(BuildContext context, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DT.s4),
      decoration: BoxDecoration(
        color: DT.gbWhite,
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        boxShadow: [
          BoxShadow(
            color: DT.of(context).shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style:
            TextStyle(color: DT.of(context).textSecondary, fontSize: DT.s3),
      ),
    );
  }
}

// ── Block row ────────────────────────────────────────────────────────────────

class _BlockRow extends StatelessWidget {
  final TrainingBlockModel block;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BlockRow({
    required this.block,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = block.covers(DateTime.now());
    final accent = isActive ? DT.metricBlue : DT.of(context).borderGrey;

    return Container(
      margin: const EdgeInsets.only(bottom: DT.s3),
      padding: const EdgeInsets.all(DT.s4),
      decoration: BoxDecoration(
        color: DT.gbWhite,
        borderRadius: BorderRadius.circular(DT.rCardSmall),
        border: Border(left: BorderSide(color: accent, width: 3)),
        boxShadow: [
          BoxShadow(
            color: DT.of(context).shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      block.focus,
                      style: TextStyle(
                        fontSize: DT.s4,
                        fontWeight: FontWeight.w700,
                        color: DT.of(context).textPrimary,
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: DT.s2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: DT.s2, vertical: 1),
                        decoration: BoxDecoration(
                          color: DT.metricBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(DT.rChip),
                        ),
                        child: const Text(
                          'aktív',
                          style: TextStyle(
                            color: DT.metricBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('yyyy.MM.dd').format(block.startDate.toLocal())} – ${DateFormat('yyyy.MM.dd').format(block.endDate.toLocal())}',
                  style: TextStyle(
                    fontSize: DT.s3,
                    color: DT.of(context).textSecondary,
                  ),
                ),
                if (block.notes != null && block.notes!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    block.notes!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: DT.s3,
                      color: DT.of(context).textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Szerkesztés',
            icon: Icon(Icons.edit_outlined,
                color: DT.of(context).iconLight, size: 20),
            onPressed: onEdit,
          ),
          IconButton(
            tooltip: 'Törlés',
            icon: const Icon(Icons.delete_outline,
                color: DT.cardRed, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ── Form (bottom sheet) ──────────────────────────────────────────────────────

class _TrainingBlockForm extends StatefulWidget {
  final String athleteId;
  final TrainingBlockModel? existing;
  const _TrainingBlockForm({required this.athleteId, this.existing});

  @override
  State<_TrainingBlockForm> createState() => _TrainingBlockFormState();
}

class _TrainingBlockFormState extends State<_TrainingBlockForm> {
  final _formKey = GlobalKey<FormState>();
  late String _focus;
  late DateTime _start;
  late DateTime _end;
  late final TextEditingController _notesCtrl;
  String? _dateError; // inline validation message (from 400)

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _focus = ex?.focus ?? TrainingBlockFocus.all.first;
    _start = ex?.startDate ?? DateTime.now();
    _end = ex?.endDate ?? DateTime.now().add(const Duration(days: 28));
    _notesCtrl = TextEditingController(text: ex?.notes ?? '');
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _end.isBefore(_start) ? _start : _end,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _end = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _dateError = null;
      _saving = true;
    });

    // Client-side end >= start guard (matches the 400 message verbatim).
    final s = DateTime(_start.year, _start.month, _start.day);
    final e = DateTime(_end.year, _end.month, _end.day);
    if (e.isBefore(s)) {
      setState(() {
        _dateError = "'endDate' must be on or after 'startDate'.";
        _saving = false;
      });
      return;
    }

    final notes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();

    final bloc = context.read<TrainingBlockBloc>();
    if (widget.existing == null) {
      bloc.add(CreateTrainingBlock(
        athleteId: widget.athleteId,
        focus: _focus,
        startDate: s,
        endDate: e,
        notes: notes,
      ));
    } else {
      bloc.add(UpdateTrainingBlock(
        id: widget.existing!.id,
        athleteId: widget.athleteId,
        focus: _focus,
        startDate: s,
        endDate: e,
        notes: notes,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TrainingBlockBloc, TrainingBlockState>(
      listener: (ctx, state) {
        if (state is TrainingBlockValidation) {
          setState(() {
            _dateError = state.message;
            _saving = false;
          });
        } else if (state is TrainingBlockOverlap) {
          // Snackbar is shown by the parent section listener (spec: "keep form open").
          if (mounted) setState(() => _saving = false);
        } else if (state is TrainingBlocksLoaded && _saving) {
          // Success — close the sheet.
          _saving = false;
          if (mounted) Navigator.of(context).pop();
        } else if (state is TrainingBlockError ||
            state is TrainingBlockForbidden) {
          if (mounted) setState(() => _saving = false);
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(DT.s5),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.existing == null
                        ? 'Új tréningblokk'
                        : 'Tréningblokk szerkesztése',
                    style: TextStyle(
                      fontSize: DT.s5,
                      fontWeight: FontWeight.w700,
                      color: DT.of(context).textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: DT.s3),
              // Focus dropdown
              DropdownButtonFormField<String>(
                initialValue: _focus,
                decoration: const InputDecoration(
                  labelText: 'Fókusz',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: TrainingBlockFocus.all
                    .map((f) =>
                        DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _focus = v);
                },
              ),
              const SizedBox(height: DT.s3),
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'Kezdés',
                      value: _start,
                      onTap: _pickStart,
                    ),
                  ),
                  const SizedBox(width: DT.s3),
                  Expanded(
                    child: _DateField(
                      label: 'Befejezés',
                      value: _end,
                      onTap: _pickEnd,
                    ),
                  ),
                ],
              ),
              if (_dateError != null) ...[
                const SizedBox(height: DT.s2),
                Text(
                  _dateError!,
                  style: const TextStyle(
                    color: DT.cardRed,
                    fontSize: DT.s3,
                  ),
                ),
              ],
              const SizedBox(height: DT.s3),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'Megjegyzés (max. 1000 karakter)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: DT.s4),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DT.metricBlue,
                    foregroundColor: DT.textWhite,
                    padding: const EdgeInsets.symmetric(vertical: DT.s3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DT.rCardSmall),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: DT.textWhite,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(widget.existing == null
                          ? 'Létrehozás'
                          : 'Mentés'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime value;
  final VoidCallback onTap;
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DT.rCardSmall),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        child: Text(
          DateFormat('yyyy.MM.dd').format(value),
          style: TextStyle(
              color: DT.of(context).textPrimary, fontSize: DT.s4),
        ),
      ),
    );
  }
}
