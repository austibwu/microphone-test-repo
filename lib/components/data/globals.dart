// import 'dart:ffi';

// ignore_for_file: non_constant_identifier_names, avoid_print

import 'package:audioplayers/audioplayers.dart';
import 'package:audiotestproject/components/audio_out/wavegenerator/wave_generator.dart';
import 'dart:io';
// import 'package:path_provider/path_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:audiotestproject/components/data/signal_processing.dart';
// import 'package:provider/provider.dart'; // ?

/** 
 * TODO:
 * separate audio player into its own controller with listeneers
 * do file paths need to be in here? bytes?
 */

// /// globals to be initialized when the app is first started.
// late Directory appCacheDir;
// late Directory appDocDir;
// late File storageFile;

/// global data structures, controllers
// var spectrumController = PowerSpectrumController();
var waveMaker = AudioOutController();
SpectrumInfo spectrumInfo = SpectrumInfo();


/// notifiers that control widget rebuilds
ValueNotifier<SpectrumData> currentView = ValueNotifier(SpectrumData(
    500, 500, 0, false, BitDepth.depth16Bit, 1, Float64List.fromList([])));
ValueNotifier<int> saveButtonNotifier = ValueNotifier(0); // not used?
ValueNotifier<List<SpectrumData>>storedLogNotifier = ValueNotifier([]);
List<SpectrumData> storedLog = storedLogNotifier.value;
ValueNotifier<bool> spectrumIsLoaded = ValueNotifier(false);
ChartProviderClass ChartProvider = ChartProviderClass();

Notifier testNotifier = Notifier(); // not used




/// stores the fields that control the audio output
/// not really a controller... just datastructure. 
/// TODO: rename, change to map?
/// class AudioOutController extends ChangeNotifier {
class AudioOutController {
  /* ---- state variables ---- */
  double volume = 0.0; // value doesnt matter???
  int audioType = 0; // TO DO: default is tone, chirp, square, triangle
  int fNought = 500; // default 500
  int fEnd = 1000;
  int steps = 0;
  BitDepth bitDepth = BitDepth.depth8Bit; // 8bit or 16bit bitdepth
  double duration = 1; // default 1 second
  bool isSweep = false; // hmmmm how to handle this?

  AudioPlayer player = AudioPlayer();
  String filePath = '';
  late File outputWave;

  // void onChanged() {
  //   notifyListeners();
  // }

  static final AudioOutController _instance = AudioOutController._internal();

  // using a factory is important
  // because it promises to return _an_ object of this type
  // but it doesn't promise to make a new one.
  factory AudioOutController() {
    return _instance;
  }

  // This named constructor is the "real" constructor
  // It'll be called exactly once, by the static property assignment above
  // it's also private, so it can only be called in this class
  AudioOutController._internal() {
    // initialization logic. idk yet
  }
}

/// stores information about current spectrum view for analysis purposes
class SpectrumInfo {
  double targetIndex = 500;
  List<FlSpot> spots = const [FlSpot(0, 0)];
  int size = 0;
  double SNR = 0;
  double THD = 0;
  double SFDR = 0;
  double peak = 0;

  static final SpectrumInfo _singleton = SpectrumInfo._internal();

  factory SpectrumInfo() {
    return _singleton;
  }

  SpectrumInfo._internal();
}

// ChartProviderClass ChartProvider = ChartProviderClass();
/// controls chart toggles
/// not fully implemented
class ChartProviderClass extends ChangeNotifier {
  double lowX = 0;
  double highX = 20000;
  bool lineTouchOn = true;
  bool yAxisUnits = false;

  set minX(double lowX) {
    this.lowX = lowX;
    notifyListeners();
  }

  set maxX(double highX) {
    this.highX = highX;
    notifyListeners();
  }

  switchLineTouch() {
    lineTouchOn = !lineTouchOn;
    print('line touch notifier: $lineTouchOn');
    notifyListeners();
  }

  switchYAxisUnits() {
    yAxisUnits = !yAxisUnits;
    notifyListeners();
  }
}

class Notifier extends ChangeNotifier {
  void onChanged() {
    print('testnotifier invoked');
    notifyListeners();
  }
}

/// class representing each instance of a recorded sample.
class SpectrumData {
  int fNought;
  int fEnd;
  int steps;
  bool isSweep;
  BitDepth bitDepth = BitDepth.depth8Bit;
  double duration;
  Float64List _fourierResponse;
  List<FlSpot> spots = const [FlSpot(0, 0)];


  SpectrumData(this.fNought, this.fEnd, this.steps, this.isSweep, this.bitDepth,
      this.duration, Float64List x) : _fourierResponse = x;
  
  Float64List get fourierResponse {
    return _fourierResponse;
  }

  set fourierResponse(Float64List fourierResponse) {
    _fourierResponse = fourierResponse;
    print('fourier response called: getting datapoints');
    spots = getDataPoints(_fourierResponse);
    // print('should be notifying!'); // debugging
    // notifyListeners();
  }

  String description() {
    String toneDescription = isSweep
        ? 'sweep from $fNought Hz to $fEnd Hz in $steps steps'
        : '$fNought Hz ';
    // String sweep = '';
    if (isSweep) {}
    var s = '$toneDescription signal with $steps steps of $duration seconds';
    return s;
  }

  SpectrumData.fromJson(Map<String, dynamic> json)
      : this(
            json['fNought'],
            json['fEnd'],
            json['steps'],
            json['isSweep'],
            bitDepthsList[json['bitDepth']]!,
            json['duration'],
            json['fourierResponse']);

  Map<String, dynamic> toJson() => {
        'fNought': fNought,
        'fEnd': fEnd,
        'steps': steps,
        'isSweep': isSweep,
        'bitDepth': reversedBitDepthsList[bitDepth],
        'duration': duration,
        'fourierResponse': fourierResponse
      };
}

// enums . to clean up later


enum SignalType {
  tone('tone', 0),
  chirp('chirp', 1),
  sweep('sweep', 3);

  const SignalType(this.label, this.place);
  final String label;
  final int place;
}

Map<String, BitDepth> bitDepthsList = {
  '8bit': BitDepth.depth8Bit,
  '16bit': BitDepth.depth16Bit,
  '32bit': BitDepth.depth32Bit,
  '32float': BitDepth.depth32Float,
};


Map<BitDepth, String> reversedBitDepthsList = {
  BitDepth.depth8Bit: '8bit',
  BitDepth.depth16Bit: '16bit',
  BitDepth.depth32Bit: '32bit',
  BitDepth.depth32Float: '32float',
};




// garbage below

/// stores fields and notifies listeners on update. stores fourier output,
///  index of fNought, and informs to render the chart
// class PowerSpectrumController with ChangeNotifier {
//   // fields
//   Float64List _fourierOutput =
//       Float64List.fromList([]); // results from running fft on given dataset
//   List<FlSpot> fourierSpots = [FlSpot(0, 0)]; // to use or not to use?
//   double targetIndex =
//       500; // the index of the target frequency. not 500, idk why its that

//   // getters
//   Float64List get fourierOutput {
//     return _fourierOutput;
//   }

//   List<FlSpot> getSpots(double minX, double maxX) {
//     int min = (minX <= 0) ? 0 : minX.toInt();
//     min *= _fourierOutput.length * 2 ~/ 44100;
//     int max =
//         (maxX >= _fourierOutput.length) ? _fourierOutput.length : maxX.toInt();
//     max *= _fourierOutput.length * 2 ~/ 44100;

//     return fourierSpots.sublist(min, max);
//   }

//   int length() {
//     return (_fourierOutput.isEmpty) ? 88200 : _fourierOutput.length;
//   }

//   // setters
//   set fourierOutput(Float64List fourierOutput) {
//     _fourierOutput = fourierOutput;
//     fourierSpots = getDataPoints(_fourierOutput);
//     print('should be notifying!');
//     notifyListeners();
//   }
// }