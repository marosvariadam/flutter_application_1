import 'package:flutter_bloc/flutter_bloc.dart';

/// For `RefreshIndicator.onRefresh` on bloc-driven lists: runs [reload]
/// (usually `bloc.add(LoadX())`) and completes once [bloc] emits a state
/// for which [isSettled] is true, e.g. `(s) => s is! XLoading`.
///
/// Subscribes before reloading so a synchronous emit isn't missed, and
/// gives up after [timeout] so the spinner can't hang if the bloc never
/// emits (an identical state is deduplicated by bloc).
Future<void> reloadAndWait<S>(
  BlocBase<S> bloc,
  void Function() reload,
  bool Function(S state) isSettled, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final settled = bloc.stream.firstWhere(isSettled);
  reload();
  try {
    await settled.timeout(timeout);
  } catch (_) {
    // Timeout or closed bloc: just stop the spinner.
  }
}
