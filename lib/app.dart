import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'data/models/contributor.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/profile_screen.dart';
import 'presentation/screens/search_screen.dart';
import 'presentation/screens/projects_screen.dart';
import 'presentation/widgets/bottom_nav_bar.dart';
import 'main.dart' show SplashScreen;

final showSplashProvider = StateProvider<bool>((ref) => true);

class GSSoCApp extends ConsumerStatefulWidget {
  GSSoCApp({super.key});

  @override
  ConsumerState<GSSoCApp> createState() => _GSSoCAppState();
}

class _GSSoCAppState extends ConsumerState<GSSoCApp> {
  bool _showSplash = true;

  final _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const MainScreenWrapper(currentIndex: 0, child: HomeScreen()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/search',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const MainScreenWrapper(currentIndex: 1, child: SearchScreen()),
          transitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final tween = Tween(begin: const Offset(0, 0.05), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOut));
            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
        ),
      ),
      GoRoute(
        path: '/profile/:id',
        pageBuilder: (context, state) {
          final creatorId = state.pathParameters['id'] ?? '';
          final contributor = state.extra is Contributor ? state.extra as Contributor : null;
          return CustomTransitionPage(
            key: state.pageKey,
            child: MainScreenWrapper(
              currentIndex: -1,
              child: ProfileScreen(creatorId: creatorId, initialContributor: contributor),
            ),
            transitionDuration: const Duration(milliseconds: 350),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              final tween =
                  Tween(begin: const Offset(1, 0), end: Offset.zero)
                      .chain(CurveTween(curve: Curves.easeOutCubic));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/projects',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const MainScreenWrapper(currentIndex: 2, child: ProjectsScreen()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return _showSplash
        ? MaterialApp(
            title: 'GSSoC 26',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            home: SplashScreen(
              onComplete: () {
                setState(() => _showSplash = false);
              },
            ),
          )
        : MaterialApp.router(
            title: 'GSSoC 26',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            routerConfig: _router,
          );
  }
}

class MainScreenWrapper extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  const MainScreenWrapper({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavBar(currentIndex: currentIndex),
    );
  }
}
