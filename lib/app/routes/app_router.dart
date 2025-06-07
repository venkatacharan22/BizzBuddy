import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart' as stream_video;

import '../../views/dashboard/dashboard_screen.dart';
import '../../views/products/products_screen.dart';
import '../../views/products/smart_input_screen.dart';
import '../../views/settings/settings_screen.dart';
import '../../views/splash/splash_screen.dart';
import '../../views/walkthrough/walkthrough_screen.dart';
import '../../views/poster_editor_screen.dart';
import '../../views/analytics/analytics_screen.dart';
import '../../views/sustainability_view.dart';
import '../../views/chat/chat_screen.dart';
import '../../views/call/call_screen.dart';
import '../../views/employees/employees_screen.dart';
import '../../providers/video_call_provider.dart';
import '../../views/call/video_call_test_screen.dart';
import '../../views/auth/auth_screen.dart';
import '../../views/auth/login_screen.dart';
import '../../views/auth/register_screen.dart';
import '../../views/call/test_call_screen.dart';
import '../../views/call/audio_room_home.dart';
import '../../views/call/audio_room_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/walkthrough',
        builder: (context, state) => const WalkthroughScreen(),
      ),
      // GoRoute(
      //   path: '/test-translation',
      //   name: 'testTranslation',
      //   builder: (context, state) => const TestTranslationScreen(),
      // ),
      GoRoute(
        path: '/video-call-test',
        builder: (context, state) => const VideoCallTestScreen(),
      ),
      GoRoute(
        path: '/test-call',
        builder: (context, state) => const TestCallScreen(),
      ),
      GoRoute(
        path: '/join-call/:callId',
        builder: (context, state) {
          final callId = state.pathParameters['callId']!;
          final videoProvider = ref.read(videoCallProvider);

          // Initialize video provider and create call
          return FutureBuilder(
            future: () async {
              await videoProvider.initialize();
              final call = await videoProvider.joinCallById(callId);
              return call;
            }(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Text('Error joining call: ${snapshot.error}'),
                  ),
                );
              }

              return CallScreen(call: snapshot.data!);
            },
          );
        },
      ),
      ShellRoute(
        builder: (context, state, child) {
          return Scaffold(
            body: Stack(
              children: [
                child,
                Positioned(
                  left: 20,
                  bottom: 10, // Position it above the navigation bar
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.go('/chat'),
                        borderRadius: BorderRadius.circular(25),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.smart_toy,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _calculateSelectedIndex(state),
              onDestinationSelected: (index) {
                switch (index) {
                  case 0:
                    context.go('/dashboard');
                    break;
                  case 1:
                    context.go('/products');
                    break;
                  case 2:
                    context.go('/analytics');
                    break;
                  case 3:
                    context.go('/poster');
                    break;
                  case 4:
                    context.go('/settings');
                    break;
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2),
                  label: 'Products',
                ),
                NavigationDestination(
                  icon: Icon(Icons.analytics_outlined),
                  selectedIcon: Icon(Icons.analytics),
                  label: 'Analytics',
                ),
                NavigationDestination(
                  icon: Icon(Icons.image_outlined),
                  selectedIcon: Icon(Icons.image),
                  label: 'Poster',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          );
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/products',
            builder: (context, state) => const ProductsScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const SmartInputScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsScreen(),
            routes: [
              GoRoute(
                path: 'sustainability',
                builder: (context, state) => const SustainabilityView(),
              ),
            ],
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => const ChatScreen(),
          ),
          GoRoute(
            path: '/poster',
            builder: (context, state) => const PosterEditorScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'employees',
                builder: (context, state) => const EmployeesScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/call',
        builder: (context, state) {
          final call = state.extra as stream_video.Call;
          return CallScreen(call: call);
        },
      ),
      GoRoute(
        path: '/audio-rooms',
        name: 'audioRooms',
        builder: (context, state) => const AudioRoomHome(),
      ),
      GoRoute(
        path: '/audio-rooms/:roomId',
        name: 'audioRoomJoin',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return FutureBuilder(
            future: ref.read(videoCallProvider).initialize().then(
                  (_) => ref.read(videoCallProvider).joinAudioRoom(roomId),
                ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  appBar: AppBar(title: const Text('Joining Audio Room')),
                  body: const Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Scaffold(
                  appBar: AppBar(title: const Text('Error')),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Failed to join audio room'),
                        const SizedBox(height: 16),
                        Text(
                          snapshot.error.toString(),
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.pop(),
                          child: const Text('Go Back'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return AudioRoomScreen(audioRoomCall: snapshot.data!);
            },
          );
        },
      ),
    ],
  );
});

int _calculateSelectedIndex(GoRouterState state) {
  final String location = state.uri.toString();
  if (location.startsWith('/dashboard')) return 0;
  if (location.startsWith('/products')) return 1;
  if (location.startsWith('/analytics')) return 2;
  if (location.startsWith('/poster')) return 3;
  if (location.startsWith('/settings')) return 4;
  return 0;
}

@TypedGoRoute<AnalyticsRoute>(
  path: '/analytics',
  name: 'Analytics',
)
class AnalyticsRoute extends GoRouteData {
  const AnalyticsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const AnalyticsScreen();
}
