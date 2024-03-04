// ignore_for_file: prefer_const_constructors, avoid_print
// import 'dart:typed_data';
import 'package:audiotestproject/components/controls/saving.dart';
// import 'package:audiotestproject/components/controls/sidebar.dart';
import 'package:audiotestproject/components/data/globals.dart';
import 'package:audiotestproject/components/data/signal_processing.dart';
import 'package:audiotestproject/components/plotting/zoomable_chart.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

class SpectrumRender extends StatefulWidget {
  const SpectrumRender({super.key});

  @override
  State<SpectrumRender> createState() => _SpectrumRenderState();
}

class _SpectrumRenderState extends State<SpectrumRender> {
  bool? saveButtonVisible;
  late List<FlSpot> spots;

  @override
  void initState() {
    super.initState();
    saveButtonVisible = true;
    spots = currentView.value.spots;
    print('graph init');
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    saveButtonVisible = true;
  }

  /// not used currently
  List<FlSpot> spotSubList(double minX, double maxX) {
    spots = currentView.value.spots;
    int lower = indexFromFreq(minX);
    int upper = indexFromFreq(maxX);
    print('minX: $minX, lower: $lower >> ${spots[lower].toString()}');
    print('maxX: $maxX, upper: $upper >> ${spots[upper].toString()}');
    print(spots[upper].toString());
    return spots.sublist(lower, upper + 1);
    // return spots.sublist(indexFromFreq(minX), indexFromFreq(maxX + 1));
  }

  @override
  build(BuildContext context) {
    // final chartcontroller = context.watch<Provider>() ;
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 2,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 10,
              right: 18,
              top: 10,
              bottom: 4,
            ),
            child: ZoomableChart(
              maxX: 20000,
              builder: (minX, maxX, focalPoint) {
                return LineChart(
                  duration: Duration(milliseconds: 2),
                  LineChartData(
                    clipData: FlClipData.all(),
                    minX: minX,
                    maxX: maxX,
                    lineTouchData: LineTouchData(
                        enabled:
                            Provider.of<ChartProviderClass>(context).lineTouchOn,
                            // ChartProvider.lineTouchOn,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) => [
                            ...touchedSpots.map((LineBarSpot touchedSpot) {
                              final textStyle = TextStyle(
                                color: touchedSpot.bar.gradient?.colors.first ??
                                    touchedSpot.bar.color ??
                                    Colors.blueGrey,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              );
                              return LineTooltipItem(
                                  ('${truncate(touchedSpot.x)} ${truncate(touchedSpot.y)} ${touchedSpot.spotIndex}'),
                                  textStyle);
                            })
                          ],
                        )),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spotSubList(minX, maxX),
                        // spots.sublist(
                        //     indexFromFreq(minX), indexFromFreq(maxX + 1)),
                        isCurved: true,
                        barWidth: 1.4,
                        color: const Color.fromARGB(255, 231, 214, 31),
                        dotData: const FlDotData(
                          show: false,
                        ),
                      ),
                    ],
                    // minY: 0,
                    // maxY: 3,
                    extraLinesData: ExtraLinesData(
                      verticalLines:
                          focalPoint == -1 ? [] : [VerticalLine(x: focalPoint)], // ignore. used to debug zoom functionality.
                    ),
                    titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          axisNameWidget: Text('Frequency (Hz)'),
                          axisNameSize: 24,
                          sideTitles: SideTitles(
                            // getTitlesWidget: ,
                            showTitles: true,
                            reservedSize: 30,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          axisNameWidget: Text('Magnitude (dB)'),
                          axisNameSize: 24,
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        )),
                    borderData: FlBorderData(
                      show: true,
                    ),
                    gridData: FlGridData(
                      show: true,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Center(
          child: (currentView.value.fourierResponse.isNotEmpty)
              ? Column(
                  children: [
                    Visibility(
                      visible: saveButtonVisible!,
                      child: TextButton(
                          onPressed: () {
                            save(currentView.value);
                            print('saved clicked');
                            setState(() {
                              saveButtonVisible = false;
                            });
                          },
                          child: Text('save this reading')),
                    ),
                  ],
                )
              : Padding(padding: EdgeInsets.all(10)),
        )
      ],
    );
  }
}
