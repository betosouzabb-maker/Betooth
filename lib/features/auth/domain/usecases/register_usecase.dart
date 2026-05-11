import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterUsecase {
  const RegisterUsecase(this._repository);

  final AuthRepository _repository;

  Future<UserEntity> call(RegisterParams params) {
    return _repository.register(
      name: params.name,
      email: params.email,
      birthDate: params.birthDate,
      phone: params.phone,
      password: params.password,
    );
  }
}

class RegisterParams {
  const RegisterParams({
    required this.name,
    required this.email,
    required this.birthDate,
    required this.phone,
    required this.password,
  });

  final String name;
  final String email;
  final DateTime birthDate;
  final String phone;
  final String password;
}