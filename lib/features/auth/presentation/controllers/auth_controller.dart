import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';

final loginUsecaseProvider = Provider<LoginUsecase>(
  (ref) => LoginUsecase(ref.watch(authRepositoryProvider)),
);

final registerUsecaseProvider = Provider<RegisterUsecase>(
  (ref) => RegisterUsecase(ref.watch(authRepositoryProvider)),
);

final logoutUsecaseProvider = Provider<LogoutUsecase>(
  (ref) => LogoutUsecase(ref.watch(authRepositoryProvider)),
);

final forgotPasswordUsecaseProvider = Provider<ForgotPasswordUsecase>(
  (ref) => ForgotPasswordUsecase(ref.watch(authRepositoryProvider)),
);

final resetPasswordUsecaseProvider = Provider<ResetPasswordUsecase>(
  (ref) => ResetPasswordUsecase(ref.watch(authRepositoryProvider)),
);

final getCurrentUserUsecaseProvider = Provider<GetCurrentUserUsecase>(
  (ref) => GetCurrentUserUsecase(ref.watch(authRepositoryProvider)),
);

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    loginUsecase: ref.watch(loginUsecaseProvider),
    registerUsecase: ref.watch(registerUsecaseProvider),
    logoutUsecase: ref.watch(logoutUsecaseProvider),
    forgotPasswordUsecase: ref.watch(forgotPasswordUsecaseProvider),
    resetPasswordUsecase: ref.watch(resetPasswordUsecaseProvider),
    getCurrentUserUsecase: ref.watch(getCurrentUserUsecaseProvider),
    authLocalDatasource: ref.watch(authLocalDatasourceProvider),
  );
});

class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required LoginUsecase loginUsecase,
    required RegisterUsecase registerUsecase,
    required LogoutUsecase logoutUsecase,
    required ForgotPasswordUsecase forgotPasswordUsecase,
    required ResetPasswordUsecase resetPasswordUsecase,
    required GetCurrentUserUsecase getCurrentUserUsecase,
    required AuthLocalDatasource authLocalDatasource,
  })  : _loginUsecase = loginUsecase,
        _registerUsecase = registerUsecase,
        _logoutUsecase = logoutUsecase,
        _forgotPasswordUsecase = forgotPasswordUsecase,
        _resetPasswordUsecase = resetPasswordUsecase,
        _getCurrentUserUsecase = getCurrentUserUsecase,
        _authLocalDatasource = authLocalDatasource,
        super(const AuthState.initial()) {
    initialize();
  }

  final LoginUsecase _loginUsecase;
  final RegisterUsecase _registerUsecase;
  final LogoutUsecase _logoutUsecase;
  final ForgotPasswordUsecase _forgotPasswordUsecase;
  final ResetPasswordUsecase _resetPasswordUsecase;
  final GetCurrentUserUsecase _getCurrentUserUsecase;
  final AuthLocalDatasource _authLocalDatasource;

  Future<void> initialize() async {
    state = state.copyWith(
      status: AuthStatus.initial,
      isLoading: true,
      clearError: true,
      clearInfo: true,
    );

    final tokens = await _authLocalDatasource.getTokens();
    if (tokens == null) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
        isLoading: false,
      );
      return;
    }

    try {
      final user = await _getCurrentUserUsecase.call();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isLoading: false,
        clearError: true,
      );
    } catch (_) {
      await _authLocalDatasource.clearTokens();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
        isLoading: false,
        clearError: true,
      );
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearInfo: true,
    );

    try {
      final user = await _loginUsecase.call(
        LoginParams(
          email: email.trim(),
          password: password,
        ),
      );

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isLoading: false,
        clearError: true,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
        isLoading: false,
        errorMessage: _resolveMessage(error),
      );
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required DateTime birthDate,
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearInfo: true,
    );

    try {
      final user = await _registerUsecase.call(
        RegisterParams(
          name: name.trim(),
          email: email.trim(),
          birthDate: birthDate,
          phone: phone.trim(),
          password: password,
        ),
      );

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isLoading: false,
        clearError: true,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
        isLoading: false,
        errorMessage: _resolveMessage(error),
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearInfo: true,
    );

    try {
      await _logoutUsecase.call();
    } finally {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
        isLoading: false,
      );
    }
  }

  Future<bool> forgotPassword({
    required String email,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearInfo: true,
    );

    try {
      await _forgotPasswordUsecase.call(
        ForgotPasswordParams(email: email.trim()),
      );
      state = state.copyWith(
        isLoading: false,
        infoMessage:
            'Se o e-mail existir, enviamos as instruções de redefinição.',
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _resolveMessage(error),
      );
      return false;
    }
  }

  Future<bool> resetPassword({
    required String token,
    required String password,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearInfo: true,
    );

    try {
      await _resetPasswordUsecase.call(
        ResetPasswordParams(
          token: token.trim(),
          password: password,
        ),
      );
      state = state.copyWith(
        isLoading: false,
        infoMessage: 'Senha redefinida com sucesso. Faça login novamente.',
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _resolveMessage(error),
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(
      clearError: true,
      clearInfo: true,
    );
  }

  String _resolveMessage(Object error) {
    if (error is AppException) {
      return error.message;
    }
    return 'Ocorreu um erro inesperado. Tente novamente.';
  }
}

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
}

class AuthState {
  const AuthState({
    required this.status,
    required this.user,
    required this.isLoading,
    required this.errorMessage,
    required this.infoMessage,
  });

  const AuthState.initial()
      : status = AuthStatus.initial,
        user = null,
        isLoading = true,
        errorMessage = null,
        infoMessage = null;

  final AuthStatus status;
  final UserEntity? user;
  final bool isLoading;
  final String? errorMessage;
  final String? infoMessage;

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    bool clearUser = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? infoMessage,
    bool clearInfo = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      infoMessage: clearInfo ? null : infoMessage ?? this.infoMessage,
    );
  }
}