import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/garments/presentation/garment_browser_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/photo/presentation/upload_photo_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/stylist/presentation/stylist_history_screen.dart';
import '../../features/stylist/presentation/stylist_screen.dart';
import '../../features/tryon/presentation/tryon_loading_screen.dart';
import '../../features/tryon/presentation/tryon_result_screen.dart';
import '../../features/wardrobe/models/wardrobe_item.dart';
import '../../features/wardrobe/presentation/add_wardrobe_item_screen.dart';
import '../../features/wardrobe/presentation/wardrobe_item_detail_screen.dart';
import '../../features/wardrobe/presentation/wardrobe_screen.dart';
import '../../shared/widgets/shell_scaffold.dart';

part 'app_router.g.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';

  // Shell tabs
  static const home = '/home';
  static const wardrobe = '/wardrobe';
  static const stylist = '/stylist';
  static const profile = '/profile';

  // Full-screen flows
  static const uploadPhoto = '/upload-photo';
  static const garmentBrowser = '/garments';
  static const tryonLoading = '/tryon/loading';
  static const tryonResult = '/tryon/result';
  static const history = '/history';
  static const addWardrobeItem = '/wardrobe/add';
  static const wardrobeItemDetail = '/wardrobe/detail';
  static const stylistHistory = '/stylist/history';
}

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull?.session != null;
      final location = state.matchedLocation;

      if (location == AppRoutes.splash) return null;

      if (!isLoggedIn) {
        if (location == AppRoutes.onboarding || location == AppRoutes.login) {
          return null;
        }
        return AppRoutes.login;
      }

      if (location == AppRoutes.login || location == AppRoutes.onboarding) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // Shell — 4-tab bottom nav
      ShellRoute(
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.wardrobe,
            builder: (context, state) => const WardrobeScreen(),
          ),
          GoRoute(
            path: AppRoutes.stylist,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return StylistScreen(
                existingSessionId: extra?['existingSessionId'] as String?,
                initialMessage: extra?['initialMessage'] as String?,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Full-screen flows
      GoRoute(
        path: AppRoutes.uploadPhoto,
        builder: (context, state) => const UploadPhotoScreen(),
      ),
      GoRoute(
        path: AppRoutes.garmentBrowser,
        builder: (context, state) => const GarmentBrowserScreen(),
      ),
      GoRoute(
        path: AppRoutes.tryonLoading,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return TryonLoadingScreen(jobId: extra?['jobId'] as String? ?? '');
        },
      ),
      GoRoute(
        path: AppRoutes.tryonResult,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return TryonResultScreen(resultId: extra?['resultId'] as String? ?? '');
        },
      ),
      GoRoute(
        path: AppRoutes.history,
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.addWardrobeItem,
        builder: (context, state) => const AddWardrobeItemScreen(),
      ),
      GoRoute(
        path: AppRoutes.wardrobeItemDetail,
        builder: (context, state) {
          final item = state.extra as WardrobeItem;
          return WardrobeItemDetailScreen(item: item);
        },
      ),
      GoRoute(
        path: AppRoutes.stylistHistory,
        builder: (context, state) => const StylistHistoryScreen(),
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Sayfa bulunamadı: ${state.error}')),
    ),
  );
}

// Splash screen
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    authState.whenData((state) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        if (state.session != null) {
          context.go(AppRoutes.home);
        } else {
          context.go(AppRoutes.onboarding);
        }
      });
    });

    return const Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      body: Center(child: _ProvaBrandMark()),
    );
  }
}

class _ProvaBrandMark extends StatelessWidget {
  const _ProvaBrandMark();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFC8A96E), Color(0xFFE8C98A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.checkroom_rounded, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 16),
        const Text(
          'PROVA',
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}
