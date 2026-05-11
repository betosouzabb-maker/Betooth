import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_client.dart';

final adminLocalStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

final adminRemoteDatasourceProvider = Provider<AdminRemoteDatasource>((ref) {
  return AdminRemoteDatasource(
    ref.watch(dioProvider),
    ref.watch(adminLocalStorageProvider),
  );
});

class AdminRemoteDatasource {
  AdminRemoteDatasource(this._dio, this._storage);

  final Dio _dio;
  final FlutterSecureStorage _storage;

  static const _adminTokenKey = 'admin_token';

  // ---------------------------------------------------------------------------
  // Token
  // ---------------------------------------------------------------------------

  Future<void> saveAdminToken(String token) =>
      _storage.write(key: _adminTokenKey, value: token);

  Future<String?> getAdminToken() => _storage.read(key: _adminTokenKey);

  Future<void> clearAdminToken() => _storage.delete(key: _adminTokenKey);

  Options _adminHeaders(String token) =>
      Options(headers: {'Authorization': 'Bearer $token'});

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------

  Future<String> loginMaster(String password) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/admin/login-master',
        data: {'password': password},
      );
      final data = response.data?['data'] as Map<String, dynamic>?;
      final token = data?['token'] as String?;
      if (token == null) throw const AppException('Token not received');
      await saveAdminToken(token);
      return token;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Dashboard
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getDashboard() async {
    final token = await _requireToken();
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/dashboard',
        options: _adminHeaders(token),
      );
      return response.data?['data'] as Map<String, dynamic>? ?? {};
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Map<String, dynamic>> getStats() async {
    final token = await _requireToken();
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/stats',
        options: _adminHeaders(token),
      );
      return response.data?['data'] as Map<String, dynamic>? ?? {};
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Users
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getUsers({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    final token = await _requireToken();
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/users',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null) 'status': status,
        },
        options: _adminHeaders(token),
      );
      return response.data?['data'] as Map<String, dynamic>? ?? {};
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> blockUser(String userId) async {
    final token = await _requireToken();
    try {
      await _dio.patch<void>(
        '/admin/users/$userId/block',
        options: _adminHeaders(token),
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> unblockUser(String userId) async {
    final token = await _requireToken();
    try {
      await _dio.patch<void>(
        '/admin/users/$userId/unblock',
        options: _adminHeaders(token),
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> deleteUser(String userId) async {
    final token = await _requireToken();
    try {
      await _dio.delete<void>(
        '/admin/users/$userId',
        options: _adminHeaders(token),
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Tracks
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getTracks({
    int page = 1,
    int limit = 20,
    String? privacy,
    String? status,
  }) async {
    final token = await _requireToken();
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/tracks',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (privacy != null) 'privacy': privacy,
          if (status != null) 'status': status,
        },
        options: _adminHeaders(token),
      );
      return response.data?['data'] as Map<String, dynamic>? ?? {};
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> blockTrack(String trackId) async {
    final token = await _requireToken();
    try {
      await _dio.patch<void>(
        '/admin/tracks/$trackId/block',
        options: _adminHeaders(token),
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> deleteTrack(String trackId) async {
    final token = await _requireToken();
    try {
      await _dio.delete<void>(
        '/admin/tracks/$trackId',
        options: _adminHeaders(token),
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Reports
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getReports({String? status}) async {
    final token = await _requireToken();
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/reports',
        queryParameters: {if (status != null) 'status': status},
        options: _adminHeaders(token),
      );
      return response.data?['data'] as Map<String, dynamic>? ?? {};
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> resolveReport(
    String reportId, {
    required String status,
    String? reason,
  }) async {
    final token = await _requireToken();
    try {
      await _dio.patch<void>(
        '/admin/reports/$reportId/resolve',
        data: {'status': status, if (reason != null) 'reason': reason},
        options: _adminHeaders(token),
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<String> _requireToken() async {
    final token = await getAdminToken();
    if (token == null) throw const AppException('Admin session expired. Please login again.');
    return token;
  }

  AppException _mapError(DioException e) {
    final message = (e.response?.data as Map<String, dynamic>?)?['error']?['message'] as String?;
    return AppException(message ?? 'Request failed');
  }
}
