import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/config/app_config.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../errors/app_exception.dart';
import '../logging/app_logger.dart';

final dioProvider = Provider<Dio>((ref) {
  final authLocalDatasource = ref.watch(authLocalDatasourceProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: const {
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      dio: dio,
      authLocalDatasource: authLocalDatasource,
    ),
  );

  return dio;
});

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required AuthLocalDatasource authLocalDatasource,
  })  : _dio = dio,
        _authLocalDatasource = authLocalDatasource;

  final Dio _dio;
  final AuthLocalDatasource _authLocalDatasource;

  static const _retryKey = 'auth_retry_attempted';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await _authLocalDatasource.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final requestOptions = err.requestOptions;

    if (statusCode != 401 ||
        requestOptions.extra[_retryKey] == true ||
        _isAuthRoute(requestOptions.path)) {
      handler.next(_mapDioException(err));
      return;
    }

    final refreshToken = await _authLocalDatasource.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _authLocalDatasource.clearTokens();
      handler.next(_mapDioException(err));
      return;
    }

    try {
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
          headers: const {
            'Accept': 'application/json',
          },
        ),
      );

      final refreshResponse = await refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {
          'refreshToken': refreshToken,
        },
      );

      final payload = refreshResponse.data;
      final data = payload?['data'];
      if (data is! Map<String, dynamic>) {
        throw const AppException('Resposta inválida ao renovar sessão.');
      }

      final newAccessToken = data['accessToken'] as String?;
      final newRefreshToken = data['refreshToken'] as String?;

      if (newAccessToken == null || newRefreshToken == null) {
        throw const AppException('Tokens ausentes na renovação da sessão.');
      }

      await _authLocalDatasource.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );

      final retryOptions = requestOptions.copyWith(
        headers: {
          ...requestOptions.headers,
          'Authorization': 'Bearer $newAccessToken',
        },
        extra: {
          ...requestOptions.extra,
          _retryKey: true,
        },
      );

      final response = await _dio.fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } catch (error, stackTrace) {
      appLogger.w(
        'Falha ao renovar token automaticamente',
        error: error,
        stackTrace: stackTrace,
      );
      await _authLocalDatasource.clearTokens();
      handler.next(_mapUnknownError(error, err));
    }
  }

  bool _isAuthRoute(String path) {
    return path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/refresh') ||
        path.contains('/auth/logout') ||
        path.contains('/auth/forgot-password') ||
        path.contains('/auth/reset-password');
  }

  DioException _mapUnknownError(Object error, DioException original) {
    if (error is DioException) {
      return _mapDioException(error);
    }

    return DioException(
      requestOptions: original.requestOptions,
      response: original.response,
      type: original.type,
      error: error is AppException ? error : AppException(error.toString()),
    );
  }

  DioException _mapDioException(DioException error) {
    final responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final errorPayload = responseData['error'];
      if (errorPayload is Map<String, dynamic>) {
        final message = errorPayload['message'] as String?;
        if (message != null && message.isNotEmpty) {
          return error.copyWith(
            error: AppException(message),
          );
        }
      }
    }

    return error.copyWith(
      error: error.error is AppException
          ? error.error
          : const AppException('Não foi possível concluir a requisição.'),
    );
  }
}