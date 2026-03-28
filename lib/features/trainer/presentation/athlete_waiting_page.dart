import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/auth/bloc/auth_bloc.dart';
import 'package:flutter_application_1/features/trainer/bloc/athlete_status_cubit.dart';

class AthleteWaitingPage extends StatefulWidget {
  const AthleteWaitingPage({super.key});

  @override
  State<AthleteWaitingPage> createState() => _AthleteWaitingPageState();
}

class _AthleteWaitingPageState extends State<AthleteWaitingPage>
    with SingleTickerProviderStateMixin {
  Timer? _pollTimer;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Kick off initial check if not already in progress.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<AthleteStatusCubit>();
      if (cubit.state is AthleteStatusInitial) {
        cubit.check();
      }
      _startPolling();
    });
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) context.read<AthleteStatusCubit>().check();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AthleteStatusCubit, AthleteStatusState>(
      listener: (context, state) {
        // The router will redirect when status changes, but also handle
        // direct navigation here as a safety net.
        if (state is AthleteStatusNeedsForm) {
          context.go('/onboarding/survey');
        } else if (state is AthleteStatusReady) {
          context.go('/home');
        }
      },
      child: BlocBuilder<AthleteStatusCubit, AthleteStatusState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: DT.of(context).bg,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: DT.s6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    // ── Pulsing icon ──────────────────────────────────────
                    if (state is AthleteStatusLoading ||
                        state is AthleteStatusInitial)
                      const CircularProgressIndicator()
                    else
                      ScaleTransition(
                        scale: _pulseAnim,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color:
                                DT.metricBlue.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.hourglass_top_rounded,
                            size: 56,
                            color: DT.metricBlue,
                          ),
                        ),
                      ),

                    const SizedBox(height: DT.s6),

                    // ── Title ─────────────────────────────────────────────
                    Text(
                      'Edzőre várakozás',
                      style: TextStyle(
                        color: DT.of(context).textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: DT.s3),

                    // ── Subtitle ──────────────────────────────────────────
                    Text(
                      state is AthleteStatusLoading ||
                              state is AthleteStatusInitial
                          ? 'Állapot ellenőrzése…'
                          : 'Csatlakozási kérésedet elküldtük az edzőnek. '
                              'Amint elfogadja, automatikusan továbblépünk.',
                      style: TextStyle(
                        color: DT.of(context).textSecondary,
                        fontSize: DT.s4,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: DT.s8),

                    // ── Status pill ───────────────────────────────────────
                    if (state is AthleteStatusPending)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: DT.s4, vertical: DT.s2),
                        decoration: BoxDecoration(
                          color: DT.cardYellow.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(DT.rChip),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: DT.cardYellow,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: DT.s2),
                            const Text(
                              'Jóváhagyásra vár',
                              style: TextStyle(
                                color: Color(0xFFB8860B),
                                fontWeight: FontWeight.w600,
                                fontSize: DT.s3,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const Spacer(),

                    // ── Action buttons ────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/athlete-requests'),
                        icon: const Icon(Icons.person_search_outlined,
                            color: Colors.white),
                        label: const Text(
                          'Edzőhöz csatlakozás',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: DT.s4,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DT.metricBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DT.rCardSmall),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: DT.s3),

                    TextButton(
                      onPressed: () => context.read<AthleteStatusCubit>().check(),
                      child: Text(
                        'Frissítés',
                        style: TextStyle(
                          color: DT.of(context).textSecondary,
                          fontSize: DT.s3,
                        ),
                      ),
                    ),

                    TextButton(
                      onPressed: () =>
                          context.read<AuthBloc>().add(LogoutRequested()),
                      child: const Text(
                        'Kijelentkezés',
                        style: TextStyle(
                          color: DT.cardRed,
                          fontSize: DT.s3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: DT.s6),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
