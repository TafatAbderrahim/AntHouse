import 'dart:math';
import 'package:flutter/material.dart';
import '../models/warehouse_data.dart';
import '../services/pathfinding_service.dart';

/// Represents an employee marker on the map
class EmployeeMarker {
  final String name;
  final Color color;
  final double positionX;
  final double positionY;
  final List<PathPoint>? activePath;
  final bool isSelected;
  EmployeeMarker({
    required this.name,
    required this.color,
    required this.positionX,
    required this.positionY,
    this.activePath,
    this.isSelected = false,
  });
}

class WarehouseFloorPainter extends CustomPainter {
  final WarehouseFloor floor;
  final String? selectedZoneId;
  final Offset? cursorPosition;
  final double? previewW;
  final double? previewH;
  final NavigationResult? navigationResult;
  final double animationValue;
  final List<EmployeeMarker> employeeMarkers;

  WarehouseFloorPainter({
    required this.floor,
    this.selectedZoneId,
    this.cursorPosition,
    this.previewW,
    this.previewH,
    this.navigationResult,
    this.animationValue = 0.0,
    this.employeeMarkers = const [],
  });

  double _scale(Size size) {
    final sx = size.width / floor.totalWidthM;
    final sy = size.height / floor.totalHeightM;
    return sx < sy ? sx : sy;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = _scale(size);

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, floor.totalWidthM * s, floor.totalHeightM * s),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFFF8F9FA),
    );

    _drawGrid(canvas, s);

    for (var zone in floor.zones) {
      _drawZone(canvas, zone, s);
    }

    // Active navigation path
    if (navigationResult != null) {
      _drawTargetHighlight(canvas, navigationResult!.targetZone, s);
      _drawNavigationPath(canvas, navigationResult!.path, s);
      _drawEndMarker(canvas, navigationResult!.targetZone, s);
      _drawStartMarker(canvas, navigationResult!.path, s);
    }

    // Employee markers — dots always visible, paths for selected
    for (var emp in employeeMarkers) {
      if (emp.activePath != null && emp.activePath!.length > 1) {
        _drawEmployeePath(canvas, emp, s);
      }
      _drawEmployeeDot(canvas, emp, s);
    }

    // Placement preview
    if (cursorPosition != null && previewW != null && previewH != null) {
      final rect = Rect.fromLTWH(
        cursorPosition!.dx, cursorPosition!.dy,
        previewW! * s, previewH! * s,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()
          ..color = const Color(0xFF2196F3).withValues(alpha: 0.25)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()
          ..color = const Color(0xFF2196F3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }

    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, floor.totalWidthM * s, floor.totalHeightM * s),
        const Radius.circular(6),
      ),
      Paint()
        ..color = const Color(0xFF455A64)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    _drawAxisLabels(canvas, s);
  }

  // ───────── Grid ─────────
  void _drawGrid(Canvas canvas, double s) {
    final paint = Paint()
      ..color = const Color(0xFFE0E0E0).withValues(alpha: 0.5)
      ..strokeWidth = 0.5;
    final paintMajor = Paint()
      ..color = const Color(0xFFBDBDBD).withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    for (double x = 0; x <= floor.totalWidthM; x += 1) {
      final p = x % 5 == 0 ? paintMajor : paint;
      canvas.drawLine(Offset(x * s, 0), Offset(x * s, floor.totalHeightM * s), p);
    }
    for (double y = 0; y <= floor.totalHeightM; y += 1) {
      final p = y % 5 == 0 ? paintMajor : paint;
      canvas.drawLine(Offset(0, y * s), Offset(floor.totalWidthM * s, y * s), p);
    }
  }

  // ───────── Axis labels ─────────
  void _drawAxisLabels(Canvas canvas, double s) {
    for (double x = 0; x <= floor.totalWidthM; x += 5) {
      _paintText(canvas, '${x.toInt()}m',
          Offset(x * s - 8, floor.totalHeightM * s + 2), 8,
          const Color(0xFF78909C));
    }
    for (double y = 0; y <= floor.totalHeightM; y += 5) {
      _paintText(canvas, '${y.toInt()}m',
          Offset(floor.totalWidthM * s + 2, y * s - 5), 8,
          const Color(0xFF78909C));
    }
  }

  // ───────── Zone drawing ─────────
  void _drawZone(Canvas canvas, StorageZone zone, double s) {
    final rect = Rect.fromLTWH(
        zone.x * s, zone.y * s, zone.widthM * s, zone.heightM * s);
    final isSelected = zone.id == selectedZoneId;
    final isNavTarget =
        navigationResult != null && zone.id == navigationResult!.targetZone.id;

    // ── Floor storage slots: yellow boundary markings on concrete ──
    if (zone.type == ZoneType.floorStorage) {
      _drawFloorSlot(canvas, zone, rect, s, isSelected, isNavTarget);
      return;
    }

    Color fill = _getZoneColor(zone);
    if (zone.type == ZoneType.pillar) {
      fill = Colors.white;
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()
        ..color = fill.withValues(alpha: isSelected ? 0.9 : 0.65)
        ..style = PaintingStyle.fill,
    );

    final borderColor = zone.type == ZoneType.pillar
      ? const Color(0xFF37474F)
      : isNavTarget
        ? Color.lerp(const Color(0xFFFF6D00), const Color(0xFFFFD600),
            animationValue) ??
          const Color(0xFFFF6D00)
        : isSelected
          ? const Color(0xFF1565C0)
          : fill.withValues(alpha: 0.9);
    final borderWidth = zone.type == ZoneType.pillar
      ? 1.2
      : isNavTarget
        ? 3.0
        : isSelected
          ? 3.0
          : 1.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );

    // Monte-charge: render inside shaft space + two vertical lines
    if (zone.type == ZoneType.freightElevator) {
      final insetX = (rect.width * 0.22).clamp(2.0, 8.0);
      final insetY = (rect.height * 0.12).clamp(2.0, 8.0);
      final inner = Rect.fromLTWH(
        rect.left + insetX,
        rect.top + insetY,
        (rect.width - insetX * 2).clamp(2.0, 9999.0),
        (rect.height - insetY * 2).clamp(2.0, 9999.0),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(inner, const Radius.circular(2)),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.85)
          ..style = PaintingStyle.fill,
      );

      final linePaint = Paint()
        ..color = const Color(0xFF455A64)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      final lx1 = inner.left + inner.width * 0.35;
      final lx2 = inner.left + inner.width * 0.65;
      canvas.drawLine(Offset(lx1, inner.top), Offset(lx1, inner.bottom), linePaint);
      canvas.drawLine(Offset(lx2, inner.top), Offset(lx2, inner.bottom), linePaint);
    }

    // Monte-charge labels (1er/2ème): vertical outside the box
    final isStorageFloor = floor.floorNumber >= 1 && floor.floorNumber <= 4;
    if (isStorageFloor && zone.type == ZoneType.freightElevator && zone.label.isNotEmpty) {
      final isMc2 = zone.label.contains('2');
      final sideOffset = (s * 0.55).clamp(8.0, 16.0);
      final anchor = Offset(
        isMc2 ? (zone.x * s - sideOffset) : (zone.x * s + zone.widthM * s + sideOffset),
        zone.y * s + (zone.heightM * s) / 2,
      );
      _paintRotatedText(
        canvas,
        zone.label,
        anchor,
        isMc2 ? -pi / 2 : pi / 2,
        (s * 0.65).clamp(6.0, 10.0),
        Colors.black87,
        bold: true,
      );
    }

    // Label
    if (zone.widthM * s > 16 && zone.heightM * s > 10) {
      if (isStorageFloor && zone.type == ZoneType.freightElevator) {
        return; // keep only vertical side labels for monte-charges
      }
      final fontSize = (s * 0.9).clamp(6.0, 13.0);
      _paintText(
        canvas, zone.label,
        Offset(
          zone.x * s + (zone.widthM * s) / 2 - zone.label.length * fontSize * 0.25,
          zone.y * s + (zone.heightM * s) / 2 - fontSize / 2,
        ),
        fontSize, Colors.black87, bold: true,
      );

      if (zone.heightM * s > 24) {
        final areaText = '${zone.areaM2.toStringAsFixed(1)}m²';
        _paintText(
          canvas, areaText,
          Offset(
            zone.x * s + (zone.widthM * s) / 2 - areaText.length * 3,
            zone.y * s + (zone.heightM * s) / 2 + fontSize * 0.6,
          ),
          (fontSize * 0.7).clamp(5.0, 10.0), Colors.black54,
        );

        // Show rack level info for multi-level racks (e.g. ×3 = 30 racks)
        if (zone.rackLevels > 1 && zone.heightM * s > 38) {
          final rackInfo = '×${zone.rackLevels} niv · ${zone.totalRacks} racks';
          _paintText(
            canvas, rackInfo,
            Offset(
              zone.x * s + (zone.widthM * s) / 2 - rackInfo.length * 2.5,
              zone.y * s + (zone.heightM * s) / 2 + fontSize * 1.5,
            ),
            (fontSize * 0.55).clamp(4.5, 9.0),
            const Color(0xFF1565C0),
            bold: true,
          );
        }
      }
    }

    // RDC custom visual hints (no geometry changes)
    if (floor.floorNumber == 0 && zone.type == ZoneType.office &&
        zone.label.toLowerCase().contains('bureau')) {
      _drawBureauBlackStrip(canvas, rect, s);
    }
    if (floor.floorNumber == 0 && zone.type == ZoneType.shipping) {
      _drawShippingInOutArrows(canvas, rect, s);
    }
  }

  // ───────── Floor-storage slot (yellow tape markings on concrete) ─────────
  // Divides each zone into 1m × 1m carrés (squares), like real floor markings.
  // E.g. D8 = 2m × 7m → 2 cols × 7 rows = 14 carrés.
  void _drawFloorSlot(Canvas canvas, StorageZone zone, Rect rect, double s,
      bool isSelected, bool isNavTarget) {
    final isEmpty = zone.status == ZoneStatus.empty;
    final cols = zone.widthM.round();   // number of 1m columns
    final rows = zone.heightM.round();  // number of 1m rows
    final totalSlots = cols * rows;
    // How many slots are occupied (based on occupancy rate)
    final occupiedSlots = (totalSlots * zone.occupancyRate).round();

    final cellW = rect.width / cols;
    final cellH = rect.height / rows;

    // ── Draw each 1m² carré ──
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final idx = r * cols + c;
        final isOccupied = idx < occupiedSlots;
        final cellRect = Rect.fromLTWH(
          rect.left + c * cellW,
          rect.top + r * cellH,
          cellW,
          cellH,
        );

        // Fill: concrete gray for empty, occupancy color for filled
        final fillColor = isOccupied
            ? zone.status.color.withValues(alpha: 0.45)
            : const Color(0xFFECEFF1).withValues(alpha: 0.55); // light concrete
        canvas.drawRect(cellRect, Paint()
          ..color = fillColor
          ..style = PaintingStyle.fill,
        );

        // Palette / box icon inside occupied carrés
        if (isOccupied && cellW > 8 && cellH > 8) {
          final inset = (cellW * 0.15).clamp(1.5, 4.0);
          final palRect = Rect.fromLTWH(
            cellRect.left + inset,
            cellRect.top + inset,
            cellRect.width - inset * 2,
            cellRect.height - inset * 2,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(palRect, const Radius.circular(1.5)),
            Paint()
              ..color = zone.status.color.withValues(alpha: 0.25)
              ..style = PaintingStyle.fill,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(palRect, const Radius.circular(1.5)),
            Paint()
              ..color = zone.status.color.withValues(alpha: 0.5)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.7,
          );
        }
      }
    }

    // ── Yellow tape grid lines (internal + outer boundary) ──
    final tapeColor = isEmpty
        ? const Color(0xFFFDD835).withValues(alpha: 0.4)
        : const Color(0xFFFDD835);
    final tapePaint = Paint()
      ..color = tapeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isEmpty ? 1.0 : 1.8;

    // Vertical internal lines
    for (int c = 1; c < cols; c++) {
      final lx = rect.left + c * cellW;
      canvas.drawLine(Offset(lx, rect.top), Offset(lx, rect.bottom), tapePaint);
    }
    // Horizontal internal lines
    for (int r = 1; r < rows; r++) {
      final ly = rect.top + r * cellH;
      canvas.drawLine(Offset(rect.left, ly), Offset(rect.right, ly), tapePaint);
    }

    // Outer boundary — thicker yellow tape
    final outerPaint = Paint()
      ..color = tapeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isEmpty ? 1.5 : 2.5;

    if (isEmpty) {
      _drawDashedRect(canvas, rect, tapeColor, 1.5, 6.0, 4.0);
    } else {
      canvas.drawRect(rect, outerPaint);
    }

    // ── Selection / navigation highlight ──
    if (isSelected || isNavTarget) {
      final hlColor = isNavTarget
          ? Color.lerp(const Color(0xFFFF6D00), const Color(0xFFFFD600),
                  animationValue) ??
              const Color(0xFFFF6D00)
          : const Color(0xFF1565C0);
      canvas.drawRect(rect, Paint()
        ..color = hlColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
      );
    }

    // ── Chariot pathway icon for empty zones ──
    if (isEmpty && rect.width > 18 && rect.height > 18) {
      _drawChariotIcon(canvas, rect, s);
    }

    // ── Zone label (centered) ──
    if (rect.width > 16 && rect.height > 10) {
      final fontSize = (s * 0.9).clamp(6.0, 13.0);

      // Background behind label for readability
      final labelW = zone.label.length * fontSize * 0.55 + 6;
      final labelH = fontSize + 4;
      final labelBg = Rect.fromCenter(
        center: Offset(rect.center.dx, rect.center.dy - 2),
        width: labelW,
        height: labelH,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelBg, const Radius.circular(2)),
        Paint()..color = Colors.white.withValues(alpha: 0.75),
      );

      _paintText(
        canvas,
        zone.label,
        Offset(
          rect.center.dx - zone.label.length * fontSize * 0.25,
          rect.center.dy - fontSize / 2 - 2,
        ),
        fontSize,
        isEmpty ? Colors.black38 : Colors.black87,
        bold: true,
      );

      // Slot count and area
      if (rect.height > 30) {
        final subText = isEmpty
            ? 'Passage ($totalSlots)'
            : '$occupiedSlots/$totalSlots';
        _paintText(
          canvas,
          subText,
          Offset(
            rect.center.dx - subText.length * 3,
            rect.center.dy + fontSize * 0.5,
          ),
          (fontSize * 0.65).clamp(5.0, 9.0),
          isEmpty ? const Color(0xFF78909C) : Colors.black54,
        );
      }
    }
  }

  // ───────── Dashed rectangle ─────────
  void _drawDashedRect(Canvas canvas, Rect rect, Color color, double width,
      double dashLen, double gapLen) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    // Top edge
    _drawDashedLine(canvas, Offset(rect.left, rect.top),
        Offset(rect.right, rect.top), paint, dashLen, gapLen, 0.0);
    // Right edge
    _drawDashedLine(canvas, Offset(rect.right, rect.top),
        Offset(rect.right, rect.bottom), paint, dashLen, gapLen, 0.0);
    // Bottom edge
    _drawDashedLine(canvas, Offset(rect.right, rect.bottom),
        Offset(rect.left, rect.bottom), paint, dashLen, gapLen, 0.0);
    // Left edge
    _drawDashedLine(canvas, Offset(rect.left, rect.bottom),
        Offset(rect.left, rect.top), paint, dashLen, gapLen, 0.0);
  }

  // ───────── Chariot / forklift icon ─────────
  void _drawChariotIcon(Canvas canvas, Rect rect, double s) {
    final iconSize = (s * 1.0).clamp(8.0, 16.0);
    final cx = rect.center.dx;
    final cy = rect.top + rect.height * 0.25;
    final paint = Paint()
      ..color = const Color(0xFF78909C).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Simple forklift silhouette: small box with two prongs
    final boxW = iconSize * 0.6;
    final boxH = iconSize * 0.5;
    final boxRect = Rect.fromCenter(
        center: Offset(cx, cy), width: boxW, height: boxH);
    canvas.drawRect(boxRect, paint);

    // Forks (two horizontal prongs)
    final forkLen = iconSize * 0.4;
    canvas.drawLine(
      Offset(boxRect.right, boxRect.top + boxH * 0.3),
      Offset(boxRect.right + forkLen, boxRect.top + boxH * 0.3),
      paint,
    );
    canvas.drawLine(
      Offset(boxRect.right, boxRect.top + boxH * 0.7),
      Offset(boxRect.right + forkLen, boxRect.top + boxH * 0.7),
      paint,
    );

    // Wheels (two circles)
    final wheelR = iconSize * 0.1;
    canvas.drawCircle(
      Offset(boxRect.left + boxW * 0.25, boxRect.bottom + wheelR),
      wheelR,
      paint..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(boxRect.left + boxW * 0.75, boxRect.bottom + wheelR),
      wheelR,
      Paint()
        ..color = const Color(0xFF78909C).withValues(alpha: 0.45)
        ..style = PaintingStyle.fill,
    );
  }

  void _drawBureauBlackStrip(Canvas canvas, Rect bureauRect, double s) {
    final stripH = (s * 1.1).clamp(5.0, 12.0);
    final stripW = (bureauRect.width * 0.42).clamp(36.0, 140.0);
    final stripRect = Rect.fromLTWH(
      bureauRect.left + 2,
      bureauRect.top - stripH - 1,
      stripW,
      stripH,
    );

    canvas.drawRect(stripRect, Paint()..color = Colors.black.withValues(alpha: 0.9));

    final hatch = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 0.8;
    for (double x = stripRect.left + 2; x < stripRect.right; x += 3) {
      canvas.drawLine(Offset(x, stripRect.top), Offset(x, stripRect.bottom), hatch);
    }
  }

  void _drawShippingInOutArrows(Canvas canvas, Rect shipRect, double s) {
    final len = (s * 2.8).clamp(16.0, 28.0);
    final head = (s * 0.8).clamp(5.0, 9.0);

    // OUT arrow (amber) ->
    final yOut = shipRect.top + shipRect.height * 0.34;
    final outStart = Offset(shipRect.right - len - 2, yOut);
    final outTip = Offset(shipRect.right - 2, yOut);
    _drawFlowArrow(canvas, outStart, outTip, const Color(0xFFF59E0B), head);

    // IN arrow (teal) <-
    final yIn = shipRect.top + shipRect.height * 0.52;
    final inTip = Offset(shipRect.right - len - 2, yIn);
    final inStart = Offset(shipRect.right - 2, yIn);
    _drawFlowArrow(canvas, inStart, inTip, const Color(0xFF0F766E), head);
  }

  void _drawFlowArrow(
    Canvas canvas,
    Offset start,
    Offset tip,
    Color color,
    double headSize,
  ) {
    final underlay = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, tip, underlay);

    final shaft = Paint()
      ..color = color
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, tip, shaft);

    final angle = atan2(tip.dy - start.dy, tip.dx - start.dx);
    final left = Offset(
      tip.dx - headSize * cos(angle - pi / 6),
      tip.dy - headSize * sin(angle - pi / 6),
    );
    final right = Offset(
      tip.dx - headSize * cos(angle + pi / 6),
      tip.dy - headSize * sin(angle + pi / 6),
    );
    final head = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
    canvas.drawPath(head, Paint()..color = color);
  }

  // ───────── Navigation path ─────────

  void _drawTargetHighlight(Canvas canvas, StorageZone zone, double s) {
    final pulse = 4 + 6 * sin(animationValue * 2 * pi).abs();
    final rect = Rect.fromLTWH(zone.x * s, zone.y * s, zone.widthM * s,
            zone.heightM * s)
        .inflate(pulse);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()
        ..color = const Color(0xFFFF6D00).withValues(alpha: 0.25 + 0.2 * animationValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  void _drawNavigationPath(Canvas canvas, List<PathPoint> path, double s) {
    if (path.length < 2) return;
    final points = path.map((p) => Offset(p.x * s + s / 2, p.y * s + s / 2)).toList();

    final shadowPaint = Paint()
      ..color = const Color(0xFFFF6D00).withValues(alpha: 0.18)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], shadowPaint);
    }

    final linePaint = Paint()
      ..color = const Color(0xFFFF6D00)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < points.length - 1; i++) {
      _drawDashedLine(canvas, points[i], points[i + 1], linePaint, 10, 6, animationValue);
    }

    // Animated arrows
    final totalLen = _polylineLength(points);
    if (totalLen < 1) return;
    const spacing = 40.0;
    final numArrows = (totalLen / spacing).floor();
    for (int i = 0; i < numArrows; i++) {
      final t = ((i / numArrows) + animationValue * 0.3) % 1.0;
      final arrow = _pointAlongPolyline(points, t * totalLen);
      if (arrow != null) _drawArrowHead(canvas, arrow.$1, arrow.$2, s);
    }
  }

  void _drawArrowHead(Canvas canvas, Offset tip, double angle, double s) {
    final size = (s * 0.6).clamp(6.0, 14.0);
    final paint = Paint()
      ..color = const Color(0xFFFF6D00)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final left = Offset(tip.dx + size * cos(angle + 2.6), tip.dy + size * sin(angle + 2.6));
    final right = Offset(tip.dx + size * cos(angle - 2.6), tip.dy + size * sin(angle - 2.6));
    canvas.drawLine(left, tip, paint);
    canvas.drawLine(right, tip, paint);
  }

  void _drawStartMarker(Canvas canvas, List<PathPoint> path, double s) {
    if (path.isEmpty) return;
    final cx = path.first.x * s + s / 2;
    final cy = path.first.y * s + s / 2;
    final r = (s * 0.9).clamp(8.0, 18.0);
    canvas.drawCircle(Offset(cx, cy), r * 1.5,
        Paint()..color = const Color(0xFF4CAF50).withValues(alpha: 0.2));
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = const Color(0xFF4CAF50));
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..color = const Color(0xFF2E7D32)..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawCircle(Offset(cx, cy), r * 0.4, Paint()..color = Colors.white);
  }

  void _drawEndMarker(Canvas canvas, StorageZone zone, double s) {
    final cx = zone.x * s + zone.widthM * s / 2;
    final cy = zone.y * s - (s * 1.2).clamp(10.0, 22.0);
    final pinSize = (s * 1.0).clamp(8.0, 18.0);
    canvas.drawCircle(Offset(cx, cy), pinSize, Paint()..color = const Color(0xFFFF6D00));
    canvas.drawCircle(Offset(cx, cy), pinSize * 0.45, Paint()..color = Colors.white);
    canvas.drawLine(
      Offset(cx, cy + pinSize), Offset(cx, zone.y * s),
      Paint()..color = const Color(0xFFFF6D00)..strokeWidth = 2,
    );
    _paintText(canvas, zone.label, Offset(cx - zone.label.length * 3.5, cy - pinSize - 12),
        10, const Color(0xFFFF6D00), bold: true);
  }

  // ───────── Employee markers (supervisor view) ─────────

  void _drawEmployeePath(Canvas canvas, EmployeeMarker emp, double s) {
    final points = emp.activePath!.map((p) => Offset(p.x * s + s / 2, p.y * s + s / 2)).toList();

    // Glow
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], Paint()
        ..color = emp.color.withValues(alpha: 0.15)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round);
    }

    // Dashed line
    for (int i = 0; i < points.length - 1; i++) {
      _drawDashedLine(canvas, points[i], points[i + 1],
          Paint()..color = emp.color..strokeWidth = 2.5..strokeCap = StrokeCap.round,
          8, 5, animationValue);
    }
  }

  // ───────── Employee position dot (always visible) ─────────

  void _drawEmployeeDot(Canvas canvas, EmployeeMarker emp, double s) {
    final cx = emp.positionX * s;
    final cy = emp.positionY * s;
    final r = emp.isSelected ? 14.0 : 10.0;

    // Selection pulse rings
    if (emp.isSelected) {
      canvas.drawCircle(Offset(cx, cy), r * 2.5,
          Paint()..color = emp.color.withValues(alpha: 0.08));
      canvas.drawCircle(Offset(cx, cy), r * 1.8,
          Paint()..color = emp.color.withValues(alpha: 0.18));
    }

    // White halo
    canvas.drawCircle(Offset(cx, cy), r + 3,
        Paint()..color = Colors.white);
    // Main circle
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..color = emp.color);
    // White border
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5);
    // Initial letter
    final initial = emp.name.isNotEmpty ? emp.name[0] : '?';
    _paintText(canvas, initial,
        Offset(cx - 4, cy - 5.5), r > 12 ? 11.0 : 9.0, Colors.white,
        bold: true);
    // Name label below
    _paintText(canvas, emp.name,
        Offset(cx - emp.name.length * 2.8, cy + r + 5),
        9, emp.color, bold: true);
  }

  // ───────── Helpers ─────────

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint,
      double dashLen, double gapLen, double phase) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final totalLen = sqrt(dx * dx + dy * dy);
    if (totalLen < 1) return;
    final ux = dx / totalLen;
    final uy = dy / totalLen;
    final cycle = dashLen + gapLen;
    double d = -(phase * cycle) % cycle;
    while (d < totalLen) {
      final start = max(d, 0.0);
      final end = min(d + dashLen, totalLen);
      if (end > start && start < totalLen) {
        canvas.drawLine(
          Offset(p1.dx + ux * start, p1.dy + uy * start),
          Offset(p1.dx + ux * end, p1.dy + uy * end), paint);
      }
      d += cycle;
    }
  }

  double _polylineLength(List<Offset> pts) {
    double len = 0;
    for (int i = 1; i < pts.length; i++) {
      len += (pts[i] - pts[i - 1]).distance;
    }
    return len;
  }

  (Offset, double)? _pointAlongPolyline(List<Offset> pts, double distance) {
    double acc = 0;
    for (int i = 1; i < pts.length; i++) {
      final seg = pts[i] - pts[i - 1];
      final segLen = seg.distance;
      if (acc + segLen >= distance) {
        final t = (distance - acc) / segLen;
        return (
          Offset(pts[i - 1].dx + seg.dx * t, pts[i - 1].dy + seg.dy * t),
          atan2(seg.dy, seg.dx),
        );
      }
      acc += segLen;
    }
    return null;
  }

  Color _getZoneColor(StorageZone zone) {
    switch (zone.type) {
      case ZoneType.elevator:
      case ZoneType.freightElevator:
        return const Color(0xFF90CAF9);
      case ZoneType.preparation:
        return const Color(0xFFCE93D8);
      case ZoneType.shipping:
        return const Color(0xFF80CBC4);
      case ZoneType.office:
        return const Color(0xFFBCAAA4);
      case ZoneType.bulk:
        return const Color(0xFFB39DDB);
      case ZoneType.pillar:
        return const Color(0xFFEF9A9A);
      case ZoneType.aisle:
        return const Color(0xFFE0E0E0);
      case ZoneType.floorStorage:
        // Handled by _drawFloorSlot; fallback concrete color
        return const Color(0xFFCFD8DC);
      default:
        return zone.status.color.withValues(alpha: 0.8);
    }
  }

  void _paintText(Canvas canvas, String text, Offset offset, double size,
      Color color, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color, fontSize: size,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, offset);
  }

  void _paintRotatedText(
    Canvas canvas,
    String text,
    Offset center,
    double angle,
    double size,
    Color color, {
    bool bold = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WarehouseFloorPainter old) => true;
}
