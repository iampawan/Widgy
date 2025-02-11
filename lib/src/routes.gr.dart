// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i3;
import 'package:flutter/material.dart' as _i4;
import 'package:widgy/src/pages/catalog_page.dart' as _i1;
import 'package:widgy/src/pages/widget_preview_page.dart' as _i2;

/// generated route for
/// [_i1.WidgetCatalogPage]
class WidgetCatalogRoute extends _i3.PageRouteInfo<void> {
  const WidgetCatalogRoute({List<_i3.PageRouteInfo>? children})
      : super(WidgetCatalogRoute.name, initialChildren: children);

  static const String name = 'WidgetCatalogRoute';

  static _i3.PageInfo page = _i3.PageInfo(
    name,
    builder: (data) {
      return const _i1.WidgetCatalogPage();
    },
  );
}

/// generated route for
/// [_i2.WidgetPreviewPage]
class WidgetPreviewRoute extends _i3.PageRouteInfo<WidgetPreviewRouteArgs> {
  WidgetPreviewRoute({
    _i4.Key? key,
    required String name,
    List<_i3.PageRouteInfo>? children,
  }) : super(
          WidgetPreviewRoute.name,
          args: WidgetPreviewRouteArgs(key: key, name: name),
          initialChildren: children,
        );

  static const String name = 'WidgetPreviewRoute';

  static _i3.PageInfo page = _i3.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<WidgetPreviewRouteArgs>();
      return _i2.WidgetPreviewPage(key: args.key, name: args.name);
    },
  );
}

class WidgetPreviewRouteArgs {
  const WidgetPreviewRouteArgs({this.key, required this.name});

  final _i4.Key? key;

  final String name;

  @override
  String toString() {
    return 'WidgetPreviewRouteArgs{key: $key, name: $name}';
  }
}
