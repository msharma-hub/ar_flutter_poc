import 'dart:math' as math;

import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:ar_flutter_plugin_2/widgets/ar_view.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

class MeasureObjectAR extends StatefulWidget {
  const MeasureObjectAR({super.key});

  @override
  State<MeasureObjectAR> createState() => _MeasureObjectARState();
}

class _MeasureObjectARState extends State<MeasureObjectAR> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;

  List<Vector3> points = [];
  List<ARNode> markers = [];
  List<ARNode> lines = [];

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AR Measure Object')),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: clearMeasurement,
                child: const Text("Clear Measurement"),
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
    dynamic anchorManager,
    dynamic locationManager,
  ) {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;

    arSessionManager!.onInitialize(
      showFeaturePoints: true, // Enable feature points to tap real objects
      showPlanes: true,
      customPlaneTexturePath: "Images/triangle.png",
      showWorldOrigin: true,
    );

    arObjectManager!.onInitialize();

    arSessionManager!.onPlaneOrPointTap = onTap;
  }

  Future<void> onTap(List<ARHitTestResult> hits) async {
    if (hits.isEmpty) return;

    // Use feature points for measuring real objects
    final hit = hits.firstWhere(
      (h) => h.type == ARHitTestResultType.point,
      orElse: () => hits.first,
    );

    final pos = Vector3(
      hit.worldTransform.getColumn(3).x,
      hit.worldTransform.getColumn(3).y,
      hit.worldTransform.getColumn(3).z,
    );

    // Add small marker at tap
    final marker = ARNode(
      type: NodeType.localGLTF2,
      uri: "assets/red_sphere.glb", // small sphere model
      position: pos,
      scale: Vector3.all(0.01),
    );

    bool? added = await arObjectManager?.addNode(marker);
    if (added != true) return;

    markers.add(marker);
    points.add(pos);

    if (points.length == 2) {
      final start = points[0];
      final end = points[1];

      // Draw a cylinder/line between points
      final midpoint = (start + end) / 2;
      final distance = (end - start).length;

      final lineNode = ARNode(
        type: NodeType.localGLTF2,
        uri: "assets/line_cylinder.glb", // thin cylinder model
        position: midpoint,
        scale: Vector3(0.005, distance / 2, 0.005),
        rotation: _rotationFromVector(end - start),
      );

      await arObjectManager?.addNode(lineNode);
      lines.add(lineNode);

      final distanceCm = distance * 100;

      // Show Flutter dialog with distance
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Measurement"),
          content: Text("${distanceCm.toStringAsFixed(2)} cm"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );

      // Reset for next measurement
      points.clear();
    }
  }

  /// Compute rotation quaternion for cylinder between two points
  Vector4 _rotationFromVector(Vector3 dir) {
    dir.normalize();
    final up = Vector3(0, 1, 0);
    final axis = up.cross(dir);
    if (axis.length == 0) {
      return Vector4(0, 0, 0, 0);
    }
    final angle = math.acos(up.dot(dir).clamp(-1.0, 1.0));
    return Vector4(axis.x, axis.y, axis.z, angle);
  }

  Future<void> clearMeasurement() async {
    for (var m in markers) {
      await arObjectManager?.removeNode(m);
    }
    for (var l in lines) {
      await arObjectManager?.removeNode(l);
    }
    markers.clear();
    lines.clear();
    points.clear();
  }
}
