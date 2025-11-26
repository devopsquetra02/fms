import 'package:flutter/material.dart';
import 'package:fms/core/models/geo.dart';

/// A widget that renders a static snapshot of a map state, used for home widgets.
class WidgetMapSnapshot extends StatelessWidget {
  final List<MapMarkerModel> markers;
  final int activeCount;

  const WidgetMapSnapshot({
    super.key,
    required this.markers,
    required this.activeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 150,
      color: Colors.grey[200],
      child: Stack(
        children: [
          // Background Grid (Fake Map)
          Positioned.fill(child: CustomPaint(painter: GridPainter())),
          // Markers (Simplified)
          ...markers.take(10).map((marker) {
            // Normalize coordinates to fit in box (Mock logic)
            // In a real app, you'd project lat/lng to x/y.
            // Here we just scatter them for visual effect based on hash
            final x = (marker.position.lng.hashCode % 280).toDouble() + 10;
            final y = (marker.position.lat.hashCode % 130).toDouble() + 10;

            return Positioned(
              left: x,
              top: y,
              child: const Icon(Icons.location_on, color: Colors.red, size: 24),
            );
          }),
          // Overlay Info
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$activeCount Active Vehicles',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;

    for (var i = 0.0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (var i = 0.0; i < size.height; i += 30) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
