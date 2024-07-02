import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

import '../flutter_map_fast_markers.dart';

class FastMarkersPlugin extends StatelessWidget {
  final List<FastMarker> markers;

  const FastMarkersPlugin(
      {Key? key, required this.markers, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final MapCamera camera = MapCamera.of(context);
    final MapController controller = MapController.of(context);
    final MapOptions options = MapOptions.of(context);

    return MobileLayerTransformer(
      child: FastMarkersLayer(
        camera,
        controller,
        options,
        markers,
      ),
    );
  }
}
