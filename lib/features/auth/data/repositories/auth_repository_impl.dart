import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    remoteDatasource: ref.watch(authRemoteDatasourceProvider),
    localDatasource: ref.watch(authLocalDatasourceProvider),
  ),
);

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDatasource remoteDatasource,
    required AuthLocalDatasource localDatasource,
  })  : _remoteDatasource = remoteDatasource,
        _localDatasource = localDatasource;

  final AuthRemoteDatasource _remoteDatasource;
  final AuthLocalDatasource _localDatasource;

  @override
  Future<UserEntity> getCurrentUser() {
    return _remoteDatasource.getCurrentUser();
  }

  @override
  Future<void> forgotPassword({
    required String email,
  }) {
    return _remoteDatasource.forgotPassword(email: email);
  }

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    final session = await _remoteDatasource.login(
      email: email,
      password: password,
    );

    await _localDatasource.saveTokens(
      accessToken: session.tokens.accessToken,
      refreshToken: session.tokens.refreshToken,
    );

    return session.user;
  }

  @override
  Future<UserEntity> register({
    required String name,
    required String email,
    required DateTime birthDate,
    required String phone,
    required String password,
  }) async {
    final session = await _remoteDatasource.register(
      name: name,
      email: email,
      birthDate: birthDate,
      phone: phone,
      password: password,
    );

    await _localDatasource.saveTokens(
      accessToken: session.tokens.accessToken,
      refreshToken: session.tokens.refreshToken,
    );

    return session.user;
  }

  @override
  Future<void> logout() async {
    final refreshToken = await _localDatasource.getRefreshToken();

    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _remoteDatasource.logout(refreshToken: refreshToken);
      } finally {
        await _localDatasource.clearTokens();
      }
      return;
    }

    await _localDatasource.clearTokens();
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String password,
  }) {
    return _remoteDatasource.resetPassword(
      token: token,
      password: password,
    );
  }
}