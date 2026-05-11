import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../models/auth_session_model.dart';
import '../models/auth_tokens_model.dart';
import '../models/user_model.dart';

final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>(
  (ref) => AuthRemoteDatasource(ref.watch(dioProvider)),
);

class AuthRemoteDatasource {
  AuthRemoteDatasource(this._dio);

  final Dio _dio;

  Future<AuthSessionModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      return AuthSessionModel.fromJson(_unwrapMap(response.data));
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<AuthSessionModel> register({
    required String name,
    required String email,
    required DateTime birthDate,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'birthDate': birthDate.toIso8601String(),
          'phone': phone,
          'password': password,
        },
      );

      return AuthSessionModel.fromJson(_unwrapMap(response.data));
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<AuthTokensModel> refresh({
    required String refreshToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {
          'refreshToken': refreshToken,
        },
      );

      return AuthTokensModel.fromJson(_unwrapMap(response.data));
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<void> logout({
    required String refreshToken,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/logout',
        data: {
          'refreshToken': refreshToken,
        },
      );
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<void> forgotPassword({
    required String email,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/forgot-password',
        data: {
          'email': email,
        },
      );
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/reset-password',
        data: {
          'token': token,
          'password': password,
        },
      );
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/me');
      return UserModel.fromJson(_unwrapMap(response.data));
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Map<String, dynamic> _unwrapMap(Map<String, dynamic>? payload) {
    final data = payload?['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }

    throw const AppException('Resposta inválida da API.');
  }

  AppException _mapError(DioException error) {
    if (error.error is AppException) {
      return error.error! as AppException;
    }

    final responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final errorPayload = responseData['error'];
      if (errorPayload is Map<String, dynamic>) {
        final message = errorPayload['message'] as String?;
        if (message != null && message.isNotEmpty) {
          return AppException(message);
        }
      }
    }

    return const AppException('Não foi possível concluir a operação.');
  }
}