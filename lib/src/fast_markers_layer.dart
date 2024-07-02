import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
// import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

class FastMarker {
  final LatLng point;
  final double width;
  final double height;
  final Alignment alignment;
  final Function(Canvas canvas, Offset offset) onDraw;
  final Function() onTap;

  // TODO: Rotating
  /// If true marker will be counter rotated to the map rotation
  // final bool rotate;

  /// The origin of the coordinate system (relative to the upper left corner of
  /// this render object) in which to apply the matrix.
  ///
  /// Setting an origin is equivalent to conjugating the transform matrix by a
  /// translation. This property is provided just for convenience.
  // final Offset rotateOrigin;

  /// The alignment of the origin, relative to the size of the box.
  ///
  /// This is equivalent to setting an origin based on the size of the box.
  /// If it is specified at the same time as the [rotateOrigin], both are applied.
  ///
  /// An [AlignmentDirectional.centerStart] value is the same as an [Alignment]
  /// whose [Alignment.x] value is `-1.0` if [Directionality.of] returns
  /// [TextDirection.ltr], and `1.0` if [Directionality.of] returns
  /// [TextDirection.rtl].	 Similarly [AlignmentDirectional.centerEnd] is the
  /// same as an [Alignment] whose [Alignment.x] value is `1.0` if
  /// [Directionality.of] returns	 [TextDirection.ltr], and `-1.0` if
  /// [Directionality.of] returns [TextDirection.rtl].
  // final AlignmentGeometry rotateAlignment;

  FastMarker({
    required this.point,
    this.width = 30.0,
    this.height = 30.0,
    required this.onDraw,
    required this.onTap,
    // this.rotate,
    // this.rotateOrigin,
    // this.rotateAlignment,
    Alignment? alignment,
  }) : alignment = alignment ?? Alignment.center;
}

class MarkerLayerWidget extends StatelessWidget {
  final List<FastMarker> markers;
  final Function() onTap;

  MarkerLayerWidget({Key? key, required this.markers, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final MapCamera camera = MapCamera.of(context);
    final MapController controller = MapController.of(context);
    final MapOptions options = MapOptions.of(context);

    return FastMarkersLayer(
      camera,
      controller,
      options,
      markers,
    );
  }
}

class FastMarkersLayer extends StatefulWidget {
  final MapCamera camera;
  final MapController controller;
  final MapOptions map_options;
  final List<FastMarker> markers;
  // late final onTap;

  FastMarkersLayer(
      this.camera, this.controller, this.map_options, this.markers);

  @override
  _FastMarkersLayerState createState() => _FastMarkersLayerState();
}

class _FastMarkersLayerState extends State<FastMarkersLayer> {
  _FastMarkersPainter? painter;

  @override
  void initState() {
    super.initState();
    painter = _FastMarkersPainter(
      widget.camera,
      widget.controller,
      widget.map_options,
      widget.markers,
    );

    // widget.onTap = (p) => painter!.onTap(p.relative!);

    // widget.controller. = (p) => painter!.onTap(p.relative!);
  }

  @override
  void didUpdateWidget(covariant FastMarkersLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    painter = _FastMarkersPainter(
      widget.camera,
      widget.controller,
      widget.map_options,
      widget.markers,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // painter!.onTap(p.relative!);
        // get position of the tap
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(Offset.zero);
        painter!.onTap(localPosition);
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: StreamBuilder<int>(
          stream: widget.controller.mapEventStream
              .cast<int>(), // a Stream<int> or null
          builder: (BuildContext context, snapshot) {
            return CustomPaint(
              painter: painter,
              willChange: true,
            );
          },
        ),
      ),
    );
  }
}

class _FastMarkersPainter extends CustomPainter {
  final MapCamera camera;
  final MapController controller;
  final MapOptions map_options;

  final List<FastMarker> markers;
  final List<MapEntry<Bounds, FastMarker>> markersBoundsCache = [];
  var _lastZoom = -1.0;

  _FastMarkersPainter(
      this.camera, this.controller, this.map_options, this.markers) {
    _pxCache = generatePxCache();
  }

  /// List containing cached pixel positions of markers
  /// Should be discarded when zoom changes
  // Has a fixed length of markerOpts.markers.length - better performance:
  // https://stackoverflow.com/questions/15943890/is-there-a-performance-benefit-in-using-fixed-length-lists-in-dart
  var _pxCache = <Point>[];

  // Calling this every time markerOpts change should guarantee proper length
  List<Point> generatePxCache() => List.generate(
        markers.length,
        (i) => camera.project(markers[i].point),
      );

  @override
  void paint(Canvas canvas, Size size) {
    final sameZoom = camera.zoom == _lastZoom;
    markersBoundsCache.clear();
    for (var i = 0; i < markers.length; i++) {
      var marker = markers[i];

      // Decide whether to use cached point or calculate it
      var pxPoint = sameZoom ? _pxCache[i] : camera.project(marker.point);
      if (!sameZoom) {
        _pxCache[i] = pxPoint;
      }

      var topLeft =
          Point(pxPoint.x - marker.alignment.x, pxPoint.y - marker.alignment.y);
      var bottomRight =
          Point(topLeft.x + marker.width, topLeft.y + marker.height);

      if (!camera.pixelBounds
          .containsPartialBounds(Bounds(topLeft, bottomRight))) {
        continue;
      }

      final pos = (topLeft - camera.pixelOrigin);
      // TODO: Rotating
      marker.onDraw(canvas, pos.toOffset());
      markersBoundsCache.add(
        MapEntry(
          Bounds(pos, pos + Point(marker.width, marker.height)),
          marker,
        ),
      );
    }
    _lastZoom = camera.zoom;
  }

  bool onTap(Offset pos) {
    final MapEntry<Bounds<num>, FastMarker>? marker;
    marker = markersBoundsCache.reversed.firstWhereOrNull(
      (e) => e.key.contains(Point(pos.dx, pos.dy)),
    );

    if (marker != null) {
      marker.value.onTap();
      return false;
    } else {
      return true;
    }
  }

  @override
  bool shouldRepaint(covariant _FastMarkersPainter oldDelegate) {
    return true;
  }
}

// https://github.com/dart-lang/sdk/issues/42947
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
