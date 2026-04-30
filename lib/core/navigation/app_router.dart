import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/login_screen.dart';
import '../../presentation/screens/attendee_feed.dart';
import '../../presentation/screens/organizer_dashboard.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/my_tickets_screen.dart';
import '../../presentation/screens/profile_screen.dart';
import '../../presentation/screens/main_wrapper.dart'; // ✅ We'll create this next

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final roleState = ref.watch(userRoleProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      if (authState.isLoading) return null;

      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.matchedLocation == '/login';
      final isSplash = state.matchedLocation == '/splash';

      if (!isLoggedIn && !isLoggingIn && !isSplash) return '/login';

      if (isLoggedIn && (isLoggingIn || isSplash)) {
        return roleState.maybeWhen(
          data: (role) => role == 'organizer' ? '/organizer' : '/attendee',
          orElse: () => null,
        );
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // 🏗️ ORGANIZER DASHBOARD (Stays separate from Attendee Bottom Nav)
      GoRoute(
        path: '/organizer',
        builder: (context, state) => const OrganizerDashboard(),
      ),

      // 👤 ATTENDEE NESTED NAVIGATION (Member 1 Defense Point)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          // This returns the scaffold with the BottomNavigationBar
          return MainWrapper(navigationShell: navigationShell);
        },
        branches: [
          // Branch 1: Explore Feed
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/attendee',
                builder: (context, state) => const AttendeeFeed(),
              ),
            ],
          ),
          // Branch 2: My Tickets
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tickets',
                builder: (context, state) => const MyTicketsScreen(),
              ),
            ],
          ),
          // Branch 3: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});