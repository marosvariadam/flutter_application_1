import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/trainer/bloc/trainer_request_bloc.dart';
import 'package:flutter_application_1/features/trainer/data/models/trainer_request_model.dart';
import 'package:flutter_application_1/features/trainer/data/repositories/trainer_request_repository.dart';
import 'package:intl/intl.dart';

class TrainerRequestsPage extends StatelessWidget {
  /// [isTrainer] = true → trainer sees incoming requests
  /// [isTrainer] = false → athlete sees their outgoing requests
  final bool isTrainer;
  const TrainerRequestsPage({super.key, this.isTrainer = true});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) {
        final bloc =
            TrainerRequestBloc(ctx.read<TrainerRequestRepository>());
        if (isTrainer) {
          bloc.add(LoadPendingRequests());
        } else {
          bloc.add(LoadMyRequests());
        }
        return bloc;
      },
      child: _RequestsView(isTrainer: isTrainer),
    );
  }
}

class _RequestsView extends StatelessWidget {
  final bool isTrainer;
  const _RequestsView({required this.isTrainer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.of(context).bg,
      appBar: AppBar(
        backgroundColor: DT.of(context).bg,
        elevation: 0,
        leading: BackButton(color: DT.of(context).textPrimary),
        title: Text(
            isTrainer ? 'Csatlakozási kérések' : 'Az én kéréseim',
            style: TextStyle(
                color: DT.of(context).textPrimary, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: BlocConsumer<TrainerRequestBloc, TrainerRequestState>(
        listener: (context, state) {
          if (state is TrainerRequestError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is TrainerRequestLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TrainerRequestsLoaded) {
            if (state.requests.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined,
                        size: 64, color: DT.of(context).iconLightGrey),
                    const SizedBox(height: DT.s4),
                    Text(
                        isTrainer
                            ? 'Nincs függőben lévő kérés.'
                            : 'Még nem küldtél kérést.',
                        style: TextStyle(
                            color: DT.of(context).textSecondary, fontSize: DT.s4)),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(DT.s5),
              itemCount: state.requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: DT.s3),
              itemBuilder: (context, i) {
                final req = state.requests[i];
                return isTrainer
                    ? _IncomingRequestCard(request: req)
                    : _OutgoingRequestCard(request: req);
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _IncomingRequestCard extends StatelessWidget {
  final TrainerRequestModel request;
  const _IncomingRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
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
                CircleAvatar(
                  radius: 20,
                  backgroundColor: DT.metricBlue.withOpacity(0.15),
                  child: Text(
                    request.athleteFirstName.isNotEmpty
                        ? request.athleteFirstName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: DT.metricBlue,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: DT.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.athleteFullName,
                          style: TextStyle(
                              color: DT.of(context).textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: DT.s4)),
                      Text(request.athleteEmail,
                          style: TextStyle(
                              color: DT.of(context).textSecondary,
                              fontSize: DT.s3)),
                    ],
                  ),
                ),
                Text(
                  DateFormat('yyyy.MM.dd').format(request.createdAt),
                  style: TextStyle(
                      color: DT.of(context).textSecondary, fontSize: DT.s3),
                ),
              ],
            ),
            if (request.note != null && request.note!.isNotEmpty) ...[
              const SizedBox(height: DT.s3),
              Container(
                padding: const EdgeInsets.all(DT.s3),
                decoration: BoxDecoration(
                  color: DT.of(context).bg,
                  borderRadius: BorderRadius.circular(DT.rCardSmall),
                ),
                child: Text(request.note!,
                    style: TextStyle(
                        color: DT.of(context).textSecondary, fontSize: DT.s3)),
              ),
            ],
            const SizedBox(height: DT.s3),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => context
                      .read<TrainerRequestBloc>()
                      .add(RejectRequest(request.id)),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: DT.cardRed)),
                  child: const Text('Elutasítás',
                      style: TextStyle(color: DT.cardRed)),
                ),
                const SizedBox(width: DT.s3),
                ElevatedButton(
                  onPressed: () => context
                      .read<TrainerRequestBloc>()
                      .add(AcceptRequest(request.id)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: DT.metricBlue),
                  child: const Text('Elfogadás',
                      style: TextStyle(color: DT.textWhite)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OutgoingRequestCard extends StatelessWidget {
  final TrainerRequestModel request;
  const _OutgoingRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final statusColor = request.status == 'Accepted'
        ? Colors.green
        : request.status == 'Rejected'
            ? DT.cardRed
            : DT.metricBlue;
    final statusLabel = request.status == 'Accepted'
        ? 'Elfogadva'
        : request.status == 'Rejected'
            ? 'Elutasítva'
            : 'Függőben';

    return Material(
      color: DT.gbWhite,
      borderRadius: BorderRadius.circular(DT.rCardSmall),
      child: Padding(
        padding: const EdgeInsets.all(DT.s4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kérés küldve',
                      style: TextStyle(
                          color: DT.of(context).textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: DT.s4)),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('yyyy.MM.dd HH:mm')
                        .format(request.createdAt),
                    style: TextStyle(
                        color: DT.of(context).textSecondary, fontSize: DT.s3),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: DT.s3, vertical: DT.s1),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(DT.rChip),
              ),
              child: Text(statusLabel,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: DT.s3,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
