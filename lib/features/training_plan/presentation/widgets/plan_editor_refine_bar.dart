import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/training_plan/bloc/plan_editor_bloc.dart';

/// Bottom-docked NL refine bar. Submits the instruction to `/refine`,
/// shows the loading spinner while the LLM thinks, and surfaces the
/// Undo-last-refine button whenever an undo snapshot is in the state.
class PlanEditorRefineBar extends StatefulWidget {
  const PlanEditorRefineBar({super.key});

  @override
  State<PlanEditorRefineBar> createState() => _PlanEditorRefineBarState();
}

class _PlanEditorRefineBarState extends State<PlanEditorRefineBar> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit(PlanEditorBloc bloc) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    bloc.add(PlanEditorRefine(text));
    _controller.clear();
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlanEditorBloc, PlanEditorState>(
      buildWhen: (p, c) => c is PlanEditorReady,
      builder: (context, state) {
        if (state is! PlanEditorReady) return const SizedBox.shrink();
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(DT.s4, DT.s2, DT.s4, DT.s2),
            decoration: BoxDecoration(
              color: DT.of(context).cardSurfaceElevated,
              border: Border(
                top: BorderSide(color: DT.of(context).borderLight),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.refineUndo != null) ...[
                  Row(
                    children: [
                      Icon(Icons.undo,
                          size: 16, color: DT.of(context).iconLight),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'A legutóbbi finomítás visszavonható.',
                          style: TextStyle(
                              color: DT.of(context).textSecondary,
                              fontSize: DT.s3),
                        ),
                      ),
                      TextButton(
                        onPressed: state.isSaving
                            ? null
                            : () => context
                                .read<PlanEditorBloc>()
                                .add(const PlanEditorUndoRefine()),
                        child: const Text('Visszavonás',
                            style: TextStyle(color: DT.metricBlue)),
                      ),
                    ],
                  ),
                  const SizedBox(height: DT.s2),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focus,
                        maxLines: 1,
                        enabled: !state.isRefining,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) =>
                            _submit(context.read<PlanEditorBloc>()),
                        decoration: InputDecoration(
                          hintText:
                              'Finomítás… pl. "több vállizom, kevesebb térdterhelés"',
                          hintStyle:
                              TextStyle(color: DT.of(context).textSecondary),
                          filled: true,
                          fillColor: DT.of(context).bg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(DT.rCardSmall),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: DT.s3, vertical: DT.s2),
                        ),
                      ),
                    ),
                    const SizedBox(width: DT.s2),
                    SizedBox(
                      height: 44,
                      width: 44,
                      child: ElevatedButton(
                        onPressed: state.isRefining
                            ? null
                            : () => _submit(context.read<PlanEditorBloc>()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DT.metricBlue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(DT.rCardSmall),
                          ),
                        ),
                        child: state.isRefining
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
