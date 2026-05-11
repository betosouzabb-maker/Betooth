import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/repositories/subscription_repository.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class SubscriptionControllerState {
  const SubscriptionControllerState({
    this.isVip = false,
    this.subscription,
    this.downloadQuota,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  final bool isVip;
  final SubscriptionEntity? subscription;
  final DownloadQuotaEntity? downloadQuota;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  SubscriptionControllerState copyWith({
    bool? isVip,
    SubscriptionEntity? subscription,
    bool clearSubscription = false,
    DownloadQuotaEntity? downloadQuota,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return SubscriptionControllerState(
      isVip: isVip ?? this.isVip,
      subscription: clearSubscription ? null : subscription ?? this.subscription,
      downloadQuota: downloadQuota ?? this.downloadQuota,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage: clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final subscriptionControllerProvider =
    StateNotifierProvider<SubscriptionController, SubscriptionControllerState>(
  (ref) => SubscriptionController(ref.watch(subscriptionRepositoryProvider)),
);

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

class SubscriptionController
    extends StateNotifier<SubscriptionControllerState> {
  SubscriptionController(this._repository)
      : super(const SubscriptionControllerState()) {
    refresh();
  }

  final SubscriptionRepository _repository;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final result = await _repository.getMySubscription();
      state = state.copyWith(
        isVip: result.isVip,
        subscription: result.subscription,
        downloadQuota: result.downloadQuota,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _resolveMessage(e),
      );
    }
  }

  Future<String?> checkout() async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final url = await _repository.checkout();
      state = state.copyWith(isLoading: false);
      return url;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _resolveMessage(e),
      );
      return null;
    }
  }

  Future<bool> cancelSubscription() async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _repository.cancelSubscription();
      await refresh();
      state = state.copyWith(
        successMessage: 'Assinatura cancelada. Acesso VIP permanece até o fim do período.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _resolveMessage(e),
      );
      return false;
    }
  }

  Future<bool> redeemCoupon(String code) async {
    if (code.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Digite o código do cupom.');
      return false;
    }
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final message = await _repository.redeemCoupon(code.trim());
      await refresh();
      state = state.copyWith(successMessage: message);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _resolveMessage(e),
      );
      return false;
    }
  }

  Future<Map<String, dynamic>?> validateCoupon(String code) async {
    try {
      return await _repository.validateCoupon(code.trim());
    } catch (_) {
      return null;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  String _resolveMessage(Object error) {
    if (error is AppException) return error.message;
    return 'Ocorreu um erro inesperado. Tente novamente.';
  }
}
