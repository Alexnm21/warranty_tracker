import 'package:go_router/go_router.dart';
import 'package:warranty_tracker/app/router/route_names.dart';
import 'package:warranty_tracker/app/shell_page.dart';
import 'package:warranty_tracker/features/home/presentation/views/home_view.dart';
import 'package:warranty_tracker/features/products/presentation/views/product_list_view.dart';
import 'package:warranty_tracker/features/settings/presentation/views/settings_view.dart';

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: RoutePaths.home,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellPage(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.home,
                name: RouteNames.home,
                builder: (context, state) => const HomeView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.productList,
                name: RouteNames.productList,
                builder: (context, state) => const ProductListView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.settings,
                name: RouteNames.settings,
                builder: (context, state) => const SettingsView(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
