import 'package:flutter/material.dart';
import 'package:widgy/src/routes.dart';

class WidgetIsolator extends StatelessWidget {
  const WidgetIsolator({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerDelegate: appRouter.delegate(),
      routeInformationParser: appRouter.defaultRouteParser(),
    );
  }
}
