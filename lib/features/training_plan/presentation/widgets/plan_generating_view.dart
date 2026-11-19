import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';

/// Step 2 of the plan generator wizard: spinner with a cycling stage hint
/// while `POST /api/plan/generate` runs.
class PlanGeneratingView extends StatefulWidget {
  const PlanGeneratingView({super.key});

  @override
  State<PlanGeneratingView> createState() => _PlanGeneratingViewState();
}

class _PlanGeneratingViewState extends State<PlanGeneratingView> {
  int _stageIndex = 0;
  Timer? _ticker;

  static const _stages = [
    'Jelöltek generálása…',
    'ML pontozás…',
    'Ellenőrzés…',
  ];

  @override
  void initState() {
    super.initState();
    // Cycle the hint every ~4 s. The real request takes 10–30 s, so this
    // is a UX cue, not a progress read.
    _ticker = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() {
        _stageIndex = (_stageIndex + 1) % _stages.length;
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 48, height: 48,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: DT.s5),
          Text(
            _stages[_stageIndex],
            style: TextStyle(
              color: DT.of(context).textPrimary,
              fontSize: DT.s4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: DT.s2),
          Text(
            'A generálás 10–30 másodpercet is igénybe vehet.',
            style: TextStyle(
                color: DT.of(context).textSecondary, fontSize: DT.s3),
          ),
        ],
      ),
    );
  }
}
