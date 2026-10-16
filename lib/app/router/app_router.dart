import 'package:go_router/go_router.dart';

import '../../features/home/presentation/views/home_view.dart';
import '../../features/products/presentation/pages/product_detail_page.dart';
import '../../features/products/presentation/pages/product_form_page.dart';
import '../../features/products/presentation/pages/product_list_page.dart';
import '../../features/settings/presentation/views/settings_view.dart';
import '../shell_page.dart';
import 'route_names.dart';

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
                builder: (context, state) => const ProductListPage(),
                routes: [
                  GoRoute(
                    path: 'new',
                    name: RouteNames.productNew,
                    builder: (context, state) => const ProductFormPage(),
                  ),
                  GoRoute(
                    path: ':id',
                    name: RouteNames.productDetail,
                    builder: (context, state) => ProductDetailPage(
                      productId:
                          int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        name: RouteNames.productEdit,
                        builder: (context, state) => ProductFormPage(
                          productId:
                              int.tryParse(state.pathParameters['id'] ?? '') ??
                              0,
                        ),
                      ),
                    ],
                  ),
                ],
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
