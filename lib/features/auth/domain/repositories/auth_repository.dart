import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login({
    required String email,
    required String password,
  });

  Future<UserEntity> register({
    required String name,
    required String email,
    required DateTime birthDate,
    required String phone,
    required String password,
  });

  Future<void> logout();

  Future<void> forgotPassword({
    required String email,
  });

  Future<void> resetPassword({
    required String token,
    required String password,
  });

  Future<UserEntity> getCurrentUser();
}