import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:starter/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:starter/src/features/authentication/presentation/custom_profile_screen.dart';
import 'package:starter/src/features/authentication/presentation/custom_sign_in_screen.dart';
import 'package:starter/src/features/entries/presentation/entries_screen.dart';
import 'package:starter/src/features/entries/domain/entry.dart';
import 'package:starter/src/features/jobs/domain/job.dart';
import 'package:starter/src/features/entries/presentation/entry_screen/entry_screen.dart';
import 'package:starter/src/features/jobs/presentation/job_entries_screen/job_entries_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/src/features/jobs/presentation/edit_job_screen/edit_job_screen.dart';
import 'package:starter/src/features/jobs/presentation/jobs_screen/jobs_screen.dart';
import 'package:starter/src/features/onboarding/data/onboarding_repository.dart';
import 'package:starter/src/features/onboarding/presentation/onboarding_screen.dart';
import 'package:starter/src/routing/go_router_refresh_stream.dart';
import 'package:starter/src/routing/scaffold_with_bottom_nav_bar.dart';

part 'app_router.g.dart';
/*
The app has private navigators, _rootNavigatorKey and _shellNavigatorKey, that
allow for more control over the routing. It also has an enum called AppRoute,
which defines all the routes available in the app.
 */
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

enum AppRoute {
  onboarding,
  signIn,
  jobs,
  job,
  addJob,
  editJob,
  entry,
  addEntry,
  editEntry,
  entries,
  profile,
}

@riverpod
//The goRouter provider is defined using the riverpod package, which provides
//dependency injection for the app. It depends on two other providers:
//authRepositoryProvider and onboardingRepositoryProvider.
//The goRouter provider returns a GoRouter widget, which is the main widget
//responsible for routing in the app. It has an initial location of /signIn,
//which is the first screen the user will see when they open the app.
GoRouter goRouter(GoRouterRef ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final onboardingRepository = ref.watch(onboardingRepositoryProvider);
  return GoRouter(
    initialLocation: '/signIn',
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: true,
//The GoRouter has a redirect function that determines which screen to show
//based on the current state of the app. If the user has completed the
//onboarding process, they will be redirected to the signIn screen. If they are
//already signed in, they will be redirected to the jobs screen.
    redirect: (context, state) {
      final didCompleteOnboarding = onboardingRepository.isOnboardingComplete();
      if (!didCompleteOnboarding) {
        // Always check state.subloc before returning a non-null route
        // https://github.com/flutter/packages/blob/main/packages/go_router/example/lib/redirection.dart#L78
        if (state.location != '/onboarding') {
          return '/onboarding';
        }
      }
      final isLoggedIn = authRepository.currentUser != null;
      if (isLoggedIn) {
        if (state.location.startsWith('/signIn')) {
          return '/jobs';
        }
      } else {
        if (state.location.startsWith('/jobs') ||
            state.location.startsWith('/entries') ||
            state.location.startsWith('/account')) {
          return '/signIn';
        }
      }
      return null;
    },
    refreshListenable: GoRouterRefreshStream(authRepository.authStateChanges()),
//The app has several routes, including the onboarding screen, the signIn
// screen, the jobs screen, the addJob screen, the editJob screen, the entry
// screen, the addEntry screen, the editEntry screen, the entries screen, and
// the profile screen. Each screen is represented by a GoRoute widget that
// defines the path, name, and page builder for the screen.
    routes: [
      GoRoute(
        path: '/onboarding',
        name: AppRoute.onboarding.name,
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: '/signIn',
        name: AppRoute.signIn.name,
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const CustomSignInScreen(),
        ),
      ),
//The ShellRoute widget is used to define routes that should be displayed within
// the ScaffoldWithBottomNavBar widget. This widget provides a bottom navigation
// bar that allows the user to switch between different screens.
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithBottomNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/jobs',
            name: AppRoute.jobs.name,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const JobsScreen(),
            ),
            routes: [
              GoRoute(
                path: 'add',
                name: AppRoute.addJob.name,
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) {
                  return MaterialPage(
                    key: state.pageKey,
                    fullscreenDialog: true,
                    child: const EditJobScreen(),
                  );
                },
              ),
              GoRoute(
                path: ':id',// the id part of the path can change dynamically
                name: AppRoute.job.name,
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return MaterialPage(
                    key: state.pageKey,
                    child: JobEntriesScreen(jobId: id),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'entries/add',
                    name: AppRoute.addEntry.name,
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) {
                      final jobId = state.pathParameters['id']!;
                      return MaterialPage(
                        key: state.pageKey,
                        fullscreenDialog: true,
                        child: EntryScreen(
                          jobId: jobId,
                        ),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'entries/:eid',// the eid part of the path can change dynamically
                    name: AppRoute.entry.name,
                    pageBuilder: (context, state) {
                      final jobId = state.pathParameters['id']!;
                      final entryId = state.pathParameters['eid']!;
                      final entry = state.extra as Entry?;
                      return MaterialPage(
                        key: state.pageKey,
                        child: EntryScreen(
                          jobId: jobId,
                          entryId: entryId,
                          entry: entry,
                        ),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'edit',
                    name: AppRoute.editJob.name,
                    pageBuilder: (context, state) {
                      final jobId = state.pathParameters['id'];
                      final job = state.extra as Job?;
                      return MaterialPage(
                        key: state.pageKey,
                        fullscreenDialog: true,
                        child: EditJobScreen(jobId: jobId, job: job),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/entries',
            name: AppRoute.entries.name,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const EntriesScreen(),
            ),
          ),
          GoRoute(
            path: '/account',
            name: AppRoute.profile.name,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const CustomProfileScreen(),
            ),
          ),
        ],
      ),
    ],
    //errorBuilder: (context, state) => const NotFoundScreen(),
  );
}
