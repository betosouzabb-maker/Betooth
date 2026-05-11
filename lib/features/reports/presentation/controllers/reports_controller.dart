import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/reports_remote_datasource.dart';

final reportsControllerProvider =
    StateNotifierProvider.autoDispose<ReportsController, ReportsState>(
  (ref) => ReportsController(ref.watch(reportsRemoteDatasourceProvider)),
);

class ReportsState {
  const ReportsState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;

  ReportsState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReportsState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ReportsController extends StateNotifier<ReportsState> {
  ReportsController(this._datasource) : super(const ReportsState());

  final ReportsRemoteDatasource _datasource;

  Future<bool> submitTrackReport({
    required String trackId,
    required ReportReason reason,
    String? description,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, isSuccess: false);
    try {
      await _datasource.reportTrack(
        trackId: trackId,
        reason: reason,
        description: description,
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e is Exception ? e.toString() : 'Erro ao enviar denúncia.',
      );
      return false;
    }
  }

  Future<bool> submitUserReport({
    required String userId,
    required ReportReason reason,
    String? description,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, isSuccess: false);
    try {
      await _datasource.reportUser(
        userId: userId,
        reason: reason,
        description: description,
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e is Exception ? e.toString() : 'Erro ao enviar denúncia.',
      );
      return false;
    }
  }

  void reset() {
    state = const ReportsState();
  }
}
