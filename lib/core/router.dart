import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/student/rooms_screen.dart';
import '../screens/student/room_detail_screen.dart';
import '../screens/student/apply_screen.dart';
import '../screens/student/profile_screen.dart';
import '../screens/admin/admin_screen.dart';

GoRouter buildRouter(AuthProvider auth) {
  return GoRouter(
    refreshListenable: auth,
    initialLocation: '/login',
    redirect: (context, state) {
      final loggedIn = auth.isLoggedIn;
      final onAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!loggedIn && !onAuth) return '/login';
      if (loggedIn && onAuth) {
        return auth.isAdmin ? '/admin' : '/rooms';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, _) => const RegisterScreen()),
      GoRoute(path: '/rooms', builder: (context, _) => const RoomsScreen()),
      GoRoute(
        path: '/rooms/:id',
        builder: (_, state) =>
            RoomDetailScreen(roomId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/apply/:roomId',
        builder: (_, state) =>
            ApplyScreen(roomId: state.pathParameters['roomId']!),
      ),
      GoRoute(path: '/profile', builder: (context, _) => ProfileScreen()),
      GoRoute(path: '/admin', builder: (context, _) => const AdminScreen()),
    ],
  );
}
