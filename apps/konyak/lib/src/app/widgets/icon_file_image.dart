import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../icons/icon_file_loader.dart';

class IconFileLoaderScope extends InheritedWidget {
  const IconFileLoaderScope({
    super.key,
    required this.loader,
    required super.child,
  });

  final IconFileLoader loader;

  static IconFileLoader of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<IconFileLoaderScope>();
    if (scope == null) {
      throw FlutterError(
        'IconFileLoaderScope is missing from the widget tree.',
      );
    }

    return scope.loader;
  }

  @override
  bool updateShouldNotify(IconFileLoaderScope oldWidget) =>
      loader != oldWidget.loader;
}

class IconFileImage extends StatefulWidget {
  const IconFileImage({
    super.key,
    required this.path,
    required this.fallback,
    required this.width,
    required this.height,
    this.fit = BoxFit.contain,
  });

  final String? path;
  final Widget fallback;
  final double width;
  final double height;
  final BoxFit fit;

  @override
  State<IconFileImage> createState() => _IconFileImageState();
}

class _IconFileImageState extends State<IconFileImage> {
  Future<Uint8List?>? _bytes;
  IconFileLoader? _loader;
  String? _normalizedPath;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshIconFuture();
  }

  @override
  void didUpdateWidget(IconFileImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshIconFuture();
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes == null) {
      return widget.fallback;
    }

    return FutureBuilder<Uint8List?>(
      future: bytes,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null || data.isEmpty) {
          return widget.fallback;
        }

        return Image.memory(
          data,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          errorBuilder: (context, error, stackTrace) => widget.fallback,
        );
      },
    );
  }

  void _refreshIconFuture() {
    final loader = IconFileLoaderScope.of(context);
    final normalizedPath = _normalizedIconPath(widget.path);
    if (loader == _loader && normalizedPath == _normalizedPath) {
      return;
    }

    _loader = loader;
    _normalizedPath = normalizedPath;
    _bytes = normalizedPath == null
        ? null
        : loader.loadIconBytes(normalizedPath);
  }
}

String? _normalizedIconPath(String? path) {
  final trimmed = path?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }

  return trimmed;
}
