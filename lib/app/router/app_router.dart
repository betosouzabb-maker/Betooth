import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/page_transitions.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/library/presentation/pages/library_page.dart';
import '../../features/music/presentation/pages/home_page.dart';
import '../../features/playback/presentation/pages/player_page.dart';
import '../../features/playlists/presentation/pages/playlist_detail_page.dart';
import '../../features/playlists/presentation/pages/playlists_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/presentation/pages/admin_login_page.dart';
import '../../features/equalizer/presentation/pages/equalizer_page.dart';
import '../../features/history/presentation/pages/history_page.dart';
import '../../features/lyrics/presentation/pages/lyrics_page.dart';
import '../../features/upload/presentation/pages/upload_page.dart';
import '../../features/subscription/presentation/pages/vip_paywall_page.dart';
import '../../features/subscription/presentation/pages/subscription_management_page.dart';
import '../../shared/components/app_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStatus = ref.watch(
    authControllerProvider.select((state) => state.status),
  );

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAuthRoute = location == '/' ||
          location == '/login' ||
          location == '/register' ||
          location == '/forgot-password' ||
          location == '/reset-password';

      if (authStatus == AuthStatus.initial) {
        return location == '/' ? null : '/';
      }

      if (authStatus == AuthStatus.unauthenticated && !isAuthRoute) {
        return '/login';
      }

      if (authStatus == AuthStatus.authenticated && isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => buildFadeTransitionPage<void>(
          key: state.pageKey,
          child: const SplashPage(),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => buildFadeTransitionPage<void>(
          key: state.pageKey,
          child: const LoginPage(),
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => buildFadeTransitionPage<void>(
          key: state.pageKey,
          child: const RegisterPage(),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) => buildFadeTransitionPage<void>(
          key: state.pageKey,
          child: const ForgotPasswordPage(),
        ),
      ),
      GoRoute(
        path: '/reset-password',
        pageBuilder: (context, state) => buildFadeTransitionPage<void>(
          key: state.pageKey,
          child: ResetPasswordPage(
            token: state.uri.queryParameters['token'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/favorites',
        pageBuilder: (context, state) => buildFadeTransitionPage<void>(
          key: state.pageKey,
          child: const FavoritesPage(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) => buildFadeTransitionPage<void>(
                  key: state.pageKey,
                  child: const HomePage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                pageBuilder: (context, state) => buildFadeTransitionPage<void>(
                  key: state.pageKey,
                  child: const LibraryPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                pageBuilder: (context, state) => buildFadeTransitionPage<void>(
                  key: state.pageKey,
                  child: const SearchPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/playlists',
                pageBuilder: (context, state) => buildFadeTransitionPage<void>(
                  key: state.pageKey,
                  child: const PlaylistsPage(),
                ),
                routes: [
                  GoRoute(
                    path: ':id',
                    pageBuilder: (context, state) => buildFadeTransitionPage<void>(
                      key: state.pageKey,
                      child: PlaylistDetailPage(
                        id: state.pathParameters['id'] ?? '',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) => buildFadeTransitionPage<void>(
                  key: state.pageKey,
                  child: const ProfilePage(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/player',
        pageBuilder: (context, state) => buildFadeTransitionPage<void>(
          key: state.pageKey,
          child: const PlayerPage(),
        ),
      ),
      GoRoute(
        path: '/upload',
        pageBuilder: (context, state) => buildFadeTransitionPage<void>(
          key: state.pageKey,
          child: const UploadPage(),
        ),
      ),
      // Admin panel routes (separate from main app flow)
      GoRoute(
        path: '/admin',
        pageBuilder: (context, state) => buildFadeTransitionPage<void>(
          key: state.pageKey,
          child: const AdminLoginPage(),
        ),
      ),
      GoRoute(
        path: '/admin/dashboard',
        pageBuilder: (context, state) => buildFadeTransitionPage<void>(
          key: state.pageKey,
          child: const AdminDashboardPage(),
        ),
      ),
      GoRoute(
        path: '/history',
        pageBuilder: (context, state) => buildFadeTransitionPage<void>(
          key: state.pageKey,
          child: const HistoryPage(),
        ),
      ),
      GoRoute(
        path: '/equalizer',
        pageBuilder: (context, state) => buildFadeTransitionPage<void>(
          key: state.pageKey,
          child: const EqualizerPage(),
        ),
      ),
      GoRoute(
        path: '/lyrics',
        pageBuilder: (context, state) => buildFadeTransitionPage<void>(
          key: state.pageKey,
          child: LyricsPage(
            trackId: state.uri.queryParameters['trackId'],
            trackTitle: state.uri.queryParameters['title'],
          ),
        ),
      ),
      GoRoute(
        path: '/vip',
        pageBuilder: (context, state) => buildFadeTransitionPage<void>(
          key: state.pageKey,
          child: const VipPaywallPage(),
        ),
      ),
      GoRoute(
        path: '/subscription',
        pageBuilder: (context, state) => buildFadeTransitionPage<void>(
          key: state.pageKey,
          child: const SubscriptionManagementPage(),
        ),
      ),
    ],
  );
});