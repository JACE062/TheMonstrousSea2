import 'package:flutter/widgets.dart';

/// World-space camera limits around committed history, independent of gameplay.
class NauticalCameraBounds {
  const NauticalCameraBounds({
    required this.travelled,
    required this.viewport,
    required this.sceneOffset,
    required this.minimumScale,
    required this.maximumScale,
  });
  final Rect travelled;
  final Size viewport;
  final Offset sceneOffset;
  final double minimumScale, maximumScale;

  Rect get world {
    final margin = viewport.height / minimumScale;
    return Rect.fromLTRB(
      travelled.left - 120,
      travelled.top - margin,
      travelled.right + 160,
      travelled.bottom + margin,
    );
  }

  Matrix4 constrain(Matrix4 candidate) {
    final scale = candidate.getMaxScaleOnAxis().clamp(
      minimumScale,
      maximumScale,
    );
    final visible = viewport / scale;
    final origin =
        Offset(-candidate.storage[12] / scale, -candidate.storage[13] / scale) -
        sceneOffset;
    double axis(double value, double min, double max, double span) =>
        span >= max - min
        ? (min + max - span) / 2
        : value.clamp(min, max - span);
    final bounded = Offset(
      axis(origin.dx, world.left, world.right, visible.width),
      axis(origin.dy, world.top, world.bottom, visible.height),
    );
    return Matrix4.identity()
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale)
      // InteractiveViewer reads the maximum of all three scale axes.
      ..setEntry(2, 2, scale)
      ..setTranslationRaw(
        -(bounded.dx + sceneOffset.dx) * scale,
        -(bounded.dy + sceneOffset.dy) * scale,
        0,
      );
  }
}

/// All camera writes, including InteractiveViewer inertia, use the same limits.
class NauticalCameraController extends TransformationController {
  NauticalCameraBounds? bounds;
  @override
  set value(Matrix4 candidate) =>
      super.value = bounds?.constrain(candidate) ?? candidate;
}
