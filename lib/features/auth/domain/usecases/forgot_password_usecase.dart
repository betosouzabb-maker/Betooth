import '../repositories/auth_repository.dart';

class ForgotPasswordUsecase {
  const ForgotPasswordUsecase(this._repository);

  final AuthRepository _repository;

  Future<void> call(ForgotPasswordParams params) {
    return _repository.forgotPassword(email: params.email);
  }
}

class ForgotPasswordParams {
  const ForgotPasswordParams({
    required this.email,
  });

  final String email;
}