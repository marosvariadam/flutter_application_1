import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/features/auth/data/repositories/auth_repository.dart';
import 'package:flutter_application_1/features/user/data/models/user_model.dart';
import 'package:flutter_application_1/features/user/data/repositories/user_repository.dart';

// ── Events ───────────────────────────────────────────────────────────────────
abstract class AuthEvent {}

class AppStarted extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  LoginRequested(this.email, this.password);
}

class LogoutRequested extends AuthEvent {}

/// Fired after profile edit so the AuthBloc user snapshot stays fresh.
class AuthUserUpdated extends AuthEvent {
  final UserModel user;
  AuthUserUpdated(this.user);
}

// ── States ───────────────────────────────────────────────────────────────────
abstract class AuthState {}

/// App just launched; token check in progress — router must not redirect yet.
class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// ── BLoC ─────────────────────────────────────────────────────────────────────
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepo;
  final UserRepository _userRepo;

  AuthBloc({
    required AuthRepository authRepo,
    required UserRepository userRepo,
  })  : _authRepo = authRepo,
        _userRepo = userRepo,
        super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLogin);
    on<LogoutRequested>(_onLogout);
    on<AuthUserUpdated>(_onUserUpdated);
  }

  Future<void> _onAppStarted(
      AppStarted event, Emitter<AuthState> emit) async {
    final cached = await _authRepo.getCachedUser();
    if (cached == null) {
      emit(AuthUnauthenticated());
      return;
    }
    try {
      final user = await _userRepo.getUser(cached.id);
      emit(AuthAuthenticated(user));
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(
      LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final tokens = await _authRepo.login(event.email, event.password);
      final user = await _userRepo.getUser(tokens.user.id);
      emit(AuthAuthenticated(user));
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown) {
        emit(AuthError('Kapcsolódási hiba: ${e.message}'));
      } else if (e.response?.statusCode == 400 ||
          e.response?.statusCode == 401) {
        final data = e.response?.data;
        final msg = data is Map
            ? (data['message'] ?? data['title'] ?? data.toString())
            : (data?.toString() ?? 'Hibás email vagy jelszó');
        emit(AuthError(msg.toString()));
      } else {
        final status = e.response?.statusCode;
        final body = e.response?.data?.toString() ?? '(üres)';
        emit(AuthError('Szerverhiba ($status): $body'));
      }
    } on FormatException catch (e) {
      emit(AuthError('Váratlan válasz a szervertől: $e'));
    } catch (e) {
      emit(AuthError('Váratlan hiba: $e'));
    }
  }

  Future<void> _onLogout(
      LogoutRequested event, Emitter<AuthState> emit) async {
    await _authRepo.logout();
    emit(AuthUnauthenticated());
  }

  void _onUserUpdated(AuthUserUpdated event, Emitter<AuthState> emit) {
    emit(AuthAuthenticated(event.user));
  }
}
