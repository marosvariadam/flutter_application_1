import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/app/design/design_tokens.dart';
import 'package:flutter_application_1/features/session/data/models/session_model.dart';

part 'session_event.dart';
part 'session_state.dart';

class SessionBloc extends Bloc<SessionEvent, SessionState> {
  SessionBloc() : super(SessionInitial()) {
    on<LoadSessions>(_onLoadSessions);
  }

  Future<void> _onLoadSessions(
    LoadSessions event,
    Emitter<SessionState> emit,
  ) async {
    emit(SessionLoading());
    try {
      // Mock data — replace with a repository/API call when the backend is ready
      final sessions = [
        const SessionModel(
          id: '1',
          title: 'Teljes test edzés',
          trainer: 'John Doe',
          kcal: '300 kcal',
          description: 'Egy átfogó edzésprogram az egész test erősítésére.',
          duration: '45 perc',
          difficulty: 'Könnyű',
          color: DT.cardOrange,
        ),
        const SessionModel(
          id: '2',
          title: 'Felső test edzés',
          trainer: 'John Doe',
          kcal: '450 kcal',
          description: 'Edzés a felső test izmainak erősítésére.',
          duration: '45 perc',
          difficulty: 'Közepes',
          color: DT.cardYellow,
        ),
        const SessionModel(
          id: '3',
          title: 'Alsó test edzés',
          trainer: 'John Doe',
          kcal: '550 kcal',
          description: 'Edzés az alsó test izmainak erősítésére.',
          duration: '45 perc',
          difficulty: 'Nehéz',
          color: DT.cardBlue,
        ),
        const SessionModel(
          id: '4',
          title: 'Kardio edzés',
          trainer: 'Jane Smith',
          kcal: '400 kcal',
          description: 'Intenzív kardio edzés az állóképesség fejlesztésére.',
          duration: '30 perc',
          difficulty: 'Közepes',
          color: DT.cardTeal,
        ),
      ];
      emit(SessionLoaded(sessions));
    } catch (e) {
      emit(SessionError('Nem sikerült betölteni az edzéseket.'));
    }
  }
}
