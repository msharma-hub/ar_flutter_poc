import 'dart:math' as math;
import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:ar_flutter_plugin_2/widgets/ar_view.dart';
import 'package:flutter/material.dart';

import 'package:vector_math/vector_math_64.dart' as vector;

class ARDistanceMeasure extends StatefulWidget {
  const ARDistanceMeasure({super.key});

  @override
  State<ARDistanceMeasure> createState() => _ARDistanceMeasureState();
}

class _ARDistanceMeasureState extends State<ARDistanceMeasure> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;

  final List<vector.Vector3> _points = [];
  final List<ARNode> _nodes = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AR Distance Measure')),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontal,
          ),
          if (_points.length == 2)
            Positioned(
              top: 40,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Distance: ${_calculateDistance(_points[0], _points[1]).toStringAsFixed(2)} m',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;

    arSessionManager?.onInitialize(
      showFeaturePoints: true,
      showPlanes: true,
      showWorldOrigin: true,
    );

    arObjectManager?.onInitialize();

    arSessionManager?.onPlaneOrPointTap = _onPlaneTap;
  }

  Future<void> _onPlaneTap(List<ARHitTestResult> hits) async {
    if (hits.isEmpty) return;

    final hit = hits.first;
    final position = hit.worldTransform.getTranslation();

    final node = ARNode(
      type: NodeType.localGLTF2,
      uri: "assets/model.glb",
      scale: vector.Vector3.all(0.02),
      position: position,
    );

    await arObjectManager?.addNode(node);
    _nodes.add(node);
    _points.add(position);

    if (_points.length == 2) {
      final distance = _calculateDistance(_points[0], _points[1]);
      _showDistanceOverlay(distance);
    }
  }

  double _calculateDistance(vector.Vector3 p1, vector.Vector3 p2) {
    final dx = p2.x - p1.x;
    final dy = p2.y - p1.y;
    final dz = p2.z - p1.z;
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  void _showDistanceOverlay(double distance) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Distance: ${distance.toStringAsFixed(2)} m')),
    );
  }

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }
}
