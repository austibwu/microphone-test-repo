// ignore_for_file: prefer_const_constructors, avoid_print

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:audiotestproject/components/data/globals.dart';
import 'package:audiotestproject/components/plotting/zoomable_chart.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// not currently used. can probably delete this file
/// 
/// widget for the live render of recorded audio stream.

late int counter; // not necessary i think
int packetcounter = 0;

void processStream(Stream<Uint8List> broadcast) async {
  signaldata.signal = [FlSpot(0, 0)];
  counter = 0;
  broadcast.listen((ints) {
    // takes pack of bytes, reads and then turns into spots. adds to spots list
    packetcounter++;
    // print(packetcounter);
    makeSpots(convert8to16(ints));
  });
}

void makeSpots(List<int> packet) {
  print('invoked at ');
  int i = 0;
  Timer.periodic(const Duration(microseconds: 20), (timer) {
    if (i == packet.length - 1) {
      timer.cancel();
    }
    signaldata.add(FlSpot(counter.toDouble(), packet[i].toDouble()));
    counter++;
    i++;
  });
  // for (var i = 0; i < packet.length; i++) {
  // Timer(Duration(seconds: 1), () {
  //   signaldata.add(FlSpot(counter.toDouble(), packet[i].toDouble()));
  //   counter++;
  // });

  // signaldata.add(FlSpot(counter.toDouble(), packet[i].toDouble()));
  // counter++;
  // }
  print('spots: $counter');
}

List<int> convert8to16(Uint8List ints) {
  final values = <int>[];

  for (var i = 0; i < ints.length; i += 2) {
    int short = ByteData.view(Int8List.fromList([ints[i], ints[i + 1]]).buffer)
        .getInt16(0, Endian.little);
    values.add(short);
  }
  // print('convert8to16: ${values.length}');
  return values;
}

class SignalController with ChangeNotifier {
  // fields
  List<FlSpot> _signal = <FlSpot>[];

  // getters
  List<FlSpot> get signal {
    // print('streamed spots: ${_signal.length}');
    return (_signal.isEmpty) ? [FlSpot(0, 0)] : _signal;
  }

  // setters
  set signal(List<FlSpot> signal) {
    _signal = signal;
    print('signal length: ${_signal.length}');
    notifyListeners();
  }

  void add(FlSpot spot) {
    // appends batch of pcm data FlSpots
    _signal.add(spot);
    notifyListeners();
  }

  void empty() {
    _signal.clear();
  }

  List<FlSpot> subspots(int start, int end) {
    if (_signal.isEmpty) {
      return [FlSpot(0, 0)];
    }
    return _signal.sublist(start, min(_signal.length, end));
  }
}

var signaldata = SignalController();

class SignalRender extends StatefulWidget {
  const SignalRender({super.key});

  @override
  State<SignalRender> createState() => _SignalRenderState();
}

class _SignalRenderState extends State<SignalRender> {
  final double maxX = outputWave.duration * 48000;

  @override
  Widget build(BuildContext context) {
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
              maxX: maxX,
              builder: (minX, maxX, focalPoint) {
                return LineChart(
                  duration: Duration(milliseconds: 2),
                  LineChartData(
                    lineTouchData: const LineTouchData(enabled: false),
                    clipData: FlClipData.all(),
                    minX: minX,
                    maxX: maxX,
                    lineBarsData: [
                      LineChartBarData(
                        spots: signaldata.subspots(minX.toInt(), maxX.toInt()),
                        isCurved: true,
                        barWidth: 2,
                        color: const Color.fromARGB(255, 231, 214, 31),
                        dotData: const FlDotData(
                          show: false,
                        ),
                      ),
                    ],
                    minY: -1500,
                    maxY: 1500,
                    titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          axisNameWidget: Text('Audio In (time)'),
                          axisNameSize: 24,
                          sideTitles: SideTitles(
                            // showTitles: true,
                            reservedSize: 30,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          axisNameWidget: Text('Amplitude'),
                          axisNameSize: 24,
                          sideTitles: SideTitles(
                            // showTitles: true,
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
          child: Text(signaldata.signal.length.toString()),
        ),
      ],
    );
  }
}
