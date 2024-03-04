// ignore_for_file: must_be_immutable, avoid_print

import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// wrapper for chart widget, allows for scrolling, zooming, and panning.
class ZoomableChart extends StatefulWidget {
  ZoomableChart({
    super.key,
    required this.maxX,
    required this.builder,
    this.touchpadScroll = false,
  });

  double maxX;
  bool touchpadScroll;
  Widget Function(double, double, double) builder;

  @override
  State<ZoomableChart> createState() => _ZoomableChartState();
}

class _ZoomableChartState extends State<ZoomableChart> {
  late double minX;
  late double maxX;

  late double lastMaxXValue;
  late double lastMinXValue;

  double focalPoint = -1;

  bool isZoomed = false;

  late RenderBox renderBox;
  late double chartW;
  late Offset position;
  late double currPosition;

  @override
  void initState() {
    super.initState();
    minX = 0;
    maxX = widget.maxX;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      renderBox = context.findRenderObject() as RenderBox;
      chartW = renderBox.size.width;
      position = renderBox.localToGlobal(Offset.zero);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (details) {
        setState(() {
          if (isZoomed) {
            minX = 0;
            maxX = widget.maxX;
          } else {
            renderBox = context.findRenderObject() as RenderBox;
            chartW = renderBox.size.width - 65; // <-- you will need to figure out the offset from the edge of this widget to actual graph.
            position = renderBox.localToGlobal(Offset.zero);
            currPosition = details.localPosition.dx - 65; // <-----
            double currPositionX = (currPosition / chartW)*(maxX - minX) + minX;
            minX = currPositionX - 50;
            maxX = currPositionX + 50;
          }

          isZoomed = !isZoomed;
        });
      },
      trackpadScrollToScaleFactor: kDefaultTrackpadScrollToScaleFactor,
      onHorizontalDragStart: (details) {
        lastMinXValue = minX;
        lastMaxXValue = maxX;
      },
      onHorizontalDragUpdate: (details) {
        var horizontalDistance = details.primaryDelta ?? 0;
        if (horizontalDistance == 0) return;
        // print('distance : $horizontalDistance');
        var lastMinMaxDistance = max(lastMaxXValue - lastMinXValue, 0.0);
        // print(lastMinMaxDistance);
        setState(() {
          minX -= lastMinMaxDistance * 0.003 * horizontalDistance;
          maxX -= lastMinMaxDistance * 0.003 * horizontalDistance;

          if (minX <= 0) {
            minX = 0;
            maxX = lastMinMaxDistance;
          }
          if (maxX > widget.maxX) {
            maxX = widget.maxX;
            minX = maxX - lastMinMaxDistance;
          }
          // print("hordrag update x: $minX, $maxX");
        });
      },
      onScaleStart: (details) {
        lastMinXValue = minX;
        lastMaxXValue = maxX;

        renderBox = context.findRenderObject() as RenderBox;
        chartW = renderBox.size.width - 65;          // <-- you will need to figure out the offset from the edge of this widget to actual graph.
        position = renderBox.localToGlobal(Offset.zero);
        currPosition = details.localFocalPoint.dx - 65;  // <-----
      },
      onScaleUpdate: (details) {
        double leftUpdateFactor = currPosition / chartW;
        double rightUpdateFactor = 1 - leftUpdateFactor;
        var horizontalScale = details.horizontalScale;
        if (horizontalScale == 0) return;
        // print(horizontalScale);
        var lastMinMaxDistance = max(lastMaxXValue - lastMinXValue, 0);
        var newMinMaxDistance = max(lastMinMaxDistance / horizontalScale, 10);
        var distanceDifference = newMinMaxDistance - lastMinMaxDistance;
        // print("sss $lastMinMaxDistance, $newMinMaxDistance, $distanceDifference");
        setState(() {
          focalPoint = lastMinXValue + leftUpdateFactor * lastMinMaxDistance;
          final newMinX = max(
            lastMinXValue - distanceDifference * leftUpdateFactor,
            0.0,
          );
          final newMaxX = min(
            lastMaxXValue + distanceDifference * rightUpdateFactor,
            widget.maxX,
          );

          if (newMaxX - newMinX > 2) {
            minX = newMinX;
            maxX = newMaxX;
          }
          // print("window X: $minX, $maxX");
        });
      },
      onScaleEnd: (details) {
        // print('scale ended');
        setState(() {});
      },
      // onTapDown: (details) {
      // print(details);
      // print(chartW);
      // print('local clicked position: ${details.localPosition.dx}');
      // },
      // onTapCancel: () {
      //   print('tap canceled');
      // },
      child: widget.builder(minX, maxX, focalPoint),
    );
  }
}
