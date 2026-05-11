import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../data/admin_remote_datasource.dart';

final adminControllerProvider =
    StateNotifierProvider<AdminController, AdminState>((ref) {
  return AdminController(ref.watch(adminRemoteDatasourceProvider));
});

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class AdminState {
  const AdminState({
    required this.isAuthenticated,
    required this.isLoading,
    this.errorMessage,
    this.dashboard,
  });

  const AdminState.initial()
      : isAuthenticated = false,
        isLoading = false,
        errorMessage = null,
        dashboard = null;

  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;
  final Map<String, dynamic>? dashboard;

  AdminState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    Map<String, dynamic>? dashboard,
  }) {
    return AdminState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      dashboard: dashboard ?? this.dashboard,
    );
  }
}

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

class AdminController extends StateNotifier<AdminState> {
  AdminController(this._datasource) : super(const AdminState.initial()) {
    _checkStoredToken();
  }

  final AdminRemoteDatasource _datasource;

  Future<void> _checkStoredToken() async {
    final token = await _datasource.getAdminToken();
    if (token != null) {
      state = state.copyWith(isAuthenticated: true);
    }
  }

  Future<bool> login(String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _datasource.loginMaster(password);
      state = state.copyWith(isAuthenticated: true, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e is AppException ? e.message : 'Login failed',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _datasource.clearAdminToken();
    state = const AdminState.initial();
  }

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await _datasource.getDashboard();
      state = state.copyWith(isLoading: false, dashboard: data);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e is AppException ? e.message : 'Failed to load dashboard',
      );
    }
  }

  String resolveError(Object e) =>
      e is AppException ? e.message : 'An unexpected error occurred';
}
