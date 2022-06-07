import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_fast_markers/flutter_map_fast_markers.dart';

import 'fast_markers_layer.dart';

class FastMarkersPlugin extends MapPlugin {
  @override
  Widget createLayer(LayerOptions options, MapState mapState, Stream<void> stream) {
    if (options is FastMarkersLayerOptions)
      return FastMarkersLayer(options, mapState, stream);
    else
      throw (StateError("Cannot gain options"));
  }

  @override
  bool supportsLayer(LayerOptions options) {
    return options is FastMarkersLayerOptions;
  }
}
