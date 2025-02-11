import 'package:auto_route/auto_route.dart';
import 'package:widgy/src/routes.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: WidgetCatalogRoute.page, initial: true),
        AutoRoute(page: WidgetPreviewRoute.page),
        // Add other routes here
      ];
}

final appRouter = AppRouter();
