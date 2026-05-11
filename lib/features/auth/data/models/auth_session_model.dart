import 'auth_tokens_model.dart';
import 'user_model.dart';

class AuthSessionModel {
  const AuthSessionModel({
    required this.user,
    required this.tokens,
  });

  final UserModel user;
  final AuthTokensModel tokens;

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      user: UserModel.fromJson(
        Map<String, dynamic>.from(json['user'] as Map<dynamic, dynamic>),
      ),
      tokens: AuthTokensModel.fromJson(json),
    );
  }
}