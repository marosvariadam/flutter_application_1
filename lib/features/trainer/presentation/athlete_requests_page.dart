import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/trainer/bloc/trainer_request_bloc.dart';
import 'package:flutter_application_1/features/trainer/data/models/trainer_request_model.dart';
import 'package:flutter_application_1/features/trainer/data/repositories/trainer_request_repository.dart';
import 'package:intl/intl.dart';

class AthleteRequestsPage extends StatelessWidget {
  const AthleteRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => TrainerRequestBloc(ctx.read<TrainerRequestRepository>())
        ..add(LoadMyRequests()),
      child: const _AthleteRequestsView(),
    );
  }
}

class _AthleteRequestsView extends StatefulWidget {
  const _AthleteRequestsView();

  @override
  State<_AthleteRequestsView> createState() => _AthleteRequestsViewState();
}

class _AthleteRequestsViewState extends State<_AthleteRequestsView> {
  final _emailCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _send(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    context.read<TrainerRequestBloc>().add(
          SendTrainerRequest(
            _emailCtrl.text.trim(),
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.of(context).bg,
      appBar: AppBar(
        backgroundColor: DT.of(context).bg,
        elevation: 0,
        leading: BackButton(color: DT.of(context).textPrimary),
        title: Text(
          'Edzőhöz csatlakozás',
          style: TextStyle(
              color: DT.of(context).textPrimary, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<TrainerRequestBloc, TrainerRequestState>(
        listener: (context, state) {
          if (state is TrainerRequestError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is TrainerRequestSuccess) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
            _emailCtrl.clear();
            _noteCtrl.clear();
            // Reload the list after a successful send
            context.read<TrainerRequestBloc>().add(LoadMyRequests());
          }
        },
        builder: (context, state) {
          final isLoading = state is TrainerRequestLoading;
          final requests =
              state is TrainerRequestsLoaded ? state.requests : <TrainerRequestModel>[];

          return ListView(
            padding: const EdgeInsets.all(DT.s5),
            children: [
              // ── Find trainer card ───────────────────────────────────────
              _FindTrainerCard(
                formKey: _formKey,
                emailCtrl: _emailCtrl,
                noteCtrl: _noteCtrl,
                loading: isLoading,
                onSend: () => _send(context),
              ),
              const SizedBox(height: DT.s6),
              // ── My requests header ──────────────────────────────────────
              Text(
                'Kéréseim',
                style: TextStyle(
                    color: DT.of(context).textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: DT.s4),
              ),
              const SizedBox(height: DT.s3),
              // ── Requests list ───────────────────────────────────────────
              if (isLoading)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(DT.s5),
                  child: CircularProgressIndicator(),
                ))
              else if (requests.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: DT.s4),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 48, color: DT.of(context).iconLightGrey),
                        const SizedBox(height: DT.s3),
                        Text(
                          'Még nem küldtél kérést.',
                          style: TextStyle(
                              color: DT.of(context).textSecondary,
                              fontSize: DT.s3),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...requests.map((req) => Padding(
                      padding: const EdgeInsets.only(bottom: DT.s3),
                      child: _RequestCard(request: req),
                    )),
            ],
          );
        },
      ),
    );
  }
}

// ── Find trainer form card ─────────────────────────────────────────────────

class _FindTrainerCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController noteCtrl;
  final bool loading;
  final VoidCallback onSend;

  const _FindTrainerCard({
    required this.formKey,
    required this.emailCtrl,
    required this.noteCtrl,
    required this.loading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DT.s5),
      decoration: BoxDecoration(
        color: DT.gbWhite,
        borderRadius: BorderRadius.circular(DT.rCard),
        boxShadow: [
          BoxShadow(
              color: DT.of(context).shadowLight,
              blurRadius: 12,
              offset: const Offset(0, 2))
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edző keresése',
              style: TextStyle(
                  color: DT.of(context).textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: DT.s4),
            ),
            const SizedBox(height: DT.s1),
            Text(
              'Add meg az edződ email címét, és küldj csatlakozási kérést.',
              style: TextStyle(
                  color: DT.of(context).textSecondary, fontSize: DT.s3),
            ),
            const SizedBox(height: DT.s4),
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Edző email cím',
                prefixIcon: Icon(Icons.person_search_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Kötelező';
                if (!v.contains('@')) return 'Érvénytelen email';
                return null;
              },
            ),
            const SizedBox(height: DT.s3),
            TextFormField(
              controller: noteCtrl,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Bemutatkozó üzenet (opcionális)',
                prefixIcon: Icon(Icons.message_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: DT.s4),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: loading ? null : onSend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DT.metricBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DT.rCardSmall)),
                ),
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text(
                        'Kérés küldése',
                        style: TextStyle(
                            color: DT.textWhite,
                            fontWeight: FontWeight.w600,
                            fontSize: DT.s4),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Request card ───────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final TrainerRequestModel request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final statusColor = request.isAccepted
        ? Colors.green
        : request.isRejected
            ? DT.cardRed
            : DT.metricBlue;
    final statusLabel = request.isAccepted
        ? 'Elfogadva'
        : request.isRejected
            ? 'Elutasítva'
            : 'Függőben';

    return Material(
      color: DT.gbWhite,
      borderRadius: BorderRadius.circular(DT.rCardSmall),
      child: Padding(
        padding: const EdgeInsets.all(DT.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.trainerEmail ?? 'Ismeretlen edző',
                        style: TextStyle(
                            color: DT.of(context).textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: DT.s4),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('yyyy.MM.dd HH:mm').format(request.createdAt),
                        style: TextStyle(
                            color: DT.of(context).textSecondary,
                            fontSize: DT.s3),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DT.s3, vertical: DT.s1),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(DT.rChip),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: DT.s3,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (request.note != null && request.note!.isNotEmpty) ...[
              const SizedBox(height: DT.s2),
              Text(
                request.note!,
                style: TextStyle(
                    color: DT.of(context).textSecondary, fontSize: DT.s3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (request.isPending) ...[
              const SizedBox(height: DT.s3),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => _confirmCancel(context, request.id),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: DT.cardRed)),
                  child: const Text('Visszavonás',
                      style: TextStyle(color: DT.cardRed)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmCancel(BuildContext context, String requestId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kérés visszavonása'),
        content: const Text('Biztosan visszavonod a csatlakozási kérést?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Mégse')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TrainerRequestBloc>().add(CancelRequest(requestId));
            },
            child: const Text('Visszavonás',
                style: TextStyle(color: DT.cardRed)),
          ),
        ],
      ),
    );
  }
}
