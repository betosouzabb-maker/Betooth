import '../repositories/auth_repository.dart';

class ResetPasswordUsecase {
  const ResetPasswordUsecase(this._repository);

  final AuthRepository _repository;

  Future<void> call(ResetPasswordParams params) {
    return _repository.resetPassword(
      token: params.token,
      password: params.password,
    );
  }
}

class ResetPasswordParams {
  const ResetPasswordParams({
    required this.token,
    required this.password,
  });

  final String token;
  final String password;
}