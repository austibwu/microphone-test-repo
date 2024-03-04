// ignore_for_file: avoid_print, non_constant_identifier_names

import 'dart:typed_data';
import 'package:fl_chart/fl_chart.dart';
import 'package:audiotestproject/components/data/globals.dart';
import 'dart:io';
import 'package:fftea/fftea.dart';
import 'dart:math';


/// reads recorded .wav file and parses it into a list of floats representing waveform amplitude.
/// assumes pcm format is float32.
Future<void> readWAV(String recordedPath) async {
  List<double> samples = [];
  print('reading from path:$recordedPath');
  List<int> rawBytes = await File(recordedPath).readAsBytes();
  rawBytes = rawBytes.sublist(
      4096); // remove junk bytes inserted by recording plugin. leaves only PCM data. TODO: fix. should implement by searching for 'data' tag
  print('raw .wav file data length: ${rawBytes.length}. ');

  samples = parseBytes(rawBytes, samples);
  print(
      '# samples: ${samples.length}. duration: ${((samples.length / 44100) * 100).toInt() / 100} seconds');

  /// possible variables for recorded audio
  /// samplerate: 44100 or 48000 // macOS seems to only do 48000, and 4 bytes for float32
  /// channels: 1 or 2 // macOS will always do 1, iOS will respond to input
  /// bytes per sample: 2 or 4 , 4 or 8 // depends on channels
  ///
  /// (bytes per sample) * (samplerate) * (channels) = total samples
  /// if total samples !=
  // spectrumController.fourierOutput = runFourier(samples);
  print(currentView.value.fourierResponse.length);
  currentView.value.fourierResponse = runFourier(samples);
  rawBytes = [];
  samples.clear();
  // currentView.value = SpectrumData(x.fNought, x.fEnd,x.steps, x.isSweep, x.bitDepth, x.duration, runFourier(samples));
  // fftc.fourierSpots = getDataPoints(fftc.fourierOutput);
  spectrumIsLoaded.value = true;
  // fftc.fourierSpots = getDataPoints(fftc.fourierOutput);
  return;
}

List<double> parseBytes(List<int> curr, List<double> samples) {
  for (var i = 0; i < curr.length; i += 4) {
    double temp = ByteData.view(
            Int8List.fromList([curr[i], curr[i + 1], curr[i + 2], curr[i + 3]])
                .buffer)
        .getFloat32(0, Endian.little);
    samples.add(temp.toDouble());
  }
  return samples;
}

void updateCurrentView(SpectrumData curr) {
  spectrumIsLoaded.value = false;
  currentView.value = curr;
  spectrumInfo.update(curr);
  spectrumIsLoaded.value = true;
  
}

/// runs real valued fast fourier transform on given set of time domain signals
/// strips complex data and returns frequency domain magnitudes (FS^2/Hz).
/// also stores the index of the target frequency in the spectrum for later use.
Float64List runFourier(List<double> samples) {
  final fft = FFT(samples.length);
  print(FFT(samples.length).size);
  Float64List output = fft.realFft(samples).discardConjugates().magnitudes();
  spectrumInfo.targetIndex = fft.indexOfFrequency(
      outputWave.fNought.toDouble(), 44100);
  // print('length of magnitues spectrum: ${output.length}'); // debugging
  // print('index of 0hz: ${fft.indexOfFrequency(0, 44100)}');
  // print('index of 1hz: ${fft.indexOfFrequency(1, 44100)}');
  // print('index of 500hz: ${fft.indexOfFrequency(500, 44100)}');
  double upperRange = fft.indexOfFrequency(20000, 44100);
  print('index of 20000hz, this is the upper range: $upperRange'); // debugging
  // return output;
  // cut the spectrum to the index that represents 20001Hz. is this a bad idea?
  output = output.sublist(0, upperRange.toInt());
  print(output.length);
  return output.sublist(0, upperRange.toInt());
}

// useless?
void runCalculations() {
  Float64List spectrum = currentView.value.fourierResponse;
  var snrOutput = calculateSNR(spectrum);
  var thdOutput = calculateTHD(spectrum);
  var sfdrOutput = calculateSFDR(spectrum);

}

/// calculate signal to noise ratio. returns String
/// for current simplicity's sake.
(double, double, double) calculateSNR(Float64List spectrum) {
  // Float64List spectrum = fftc.fourierOutput;
  if (spectrum.isEmpty) {
    return (0,0,0);
  }

  double sumSignalPower = sumPowerAt(spectrumInfo.targetIndex, spectrum);
  double sumNoisePowers = spectrum.fold(0, (i, j) => i + j);

  double noise = (sumNoisePowers - sumSignalPower) / (spectrum.length - 6);
  double signal = sumSignalPower / 6;

  double snr = 10 * log10(signal / noise);
  return (snr, signal, noise);
  // return 'SNR for ${outputWave.fNought}Hz = ${truncate(snr)}';
}

/// Total Harmonic Distortion: calculated as the ratio of the powers
/// of integer multiples of the fundamental frequency (harmonics, also
/// called spurs) to the power of the fundamental frequency itself.
/// should account for odd harmonics only.
(double, double, double) calculateTHD(Float64List spectrum) {
    if (spectrum.isEmpty) {
    return (0,0,0);
  }
  double sumSpursPowers = 0;
  for (var i = 2; i < 5; i++) {
    sumSpursPowers += sumPowerAt(spectrumInfo.targetIndex * i, spectrum);
  }
  double sumSignalPower = sumPowerAt(spectrumInfo.targetIndex, spectrum);
  double THD = sumSpursPowers / sumSignalPower * 100;
  return (THD, sumSpursPowers, sumSignalPower);
  // return 'THD = ${truncate(THD)}%. calculated by comparing the power at ${freqFromIndex(spectrumInfo.targetIndex)}Hz and the first 5 harmonics.';
}

/// Spurious-Free Dynamic Range: the strength ratio between the
/// fundamental frequency and the next highest peak (not
/// necessarilly a spur or harmonic.). Calculated in dBFS.
/// should it be a harmonic?
(double, double, double) calculateSFDR(Float64List spectrum) {
  if (spectrum.isEmpty) {
    return (0,0,0);
  }
  int peakL = spectrumInfo.targetIndex.floor();
  int peakR = spectrumInfo.targetIndex.ceil();
  double peakFundamental = max(spectrum[peakL], spectrum[peakR]);
  peakFundamental = log10(peakFundamental);

  // find the highest peak in graph, excluding the fundamental. if
  // higher than fundamental, SFDR will be negative.
  // TODO: fix. this calculates other peaks, not necessarily harmonic peaks.
  int spurIndex = 0;
  for (var i = 0; i < spectrum.length; i++) {
    if (i < peakL - 8 || i > peakR + 8) { // 8 is arbitrary number
      if (spectrum[i] > spectrum[spurIndex]) spurIndex = i;
    }
  }
  double spurMagnitude = log10(spectrum[spurIndex]);
  double SFDR = peakFundamental - spurMagnitude;
  return (SFDR, peakFundamental, spurMagnitude);
  // return 'Spurious-Free Dynamic Range = ${truncate(SFDR)}dB. Fundamental at ${freqFromIndex(spectrumInfo.targetIndex)}Hz and spur at ${freqFromIndex(spurIndex)}Hz.';
}

/// returns the power of the spread peak at the given index of the spectrum,
/// which corresponds to the frequency. Spur powers can be found by multiplying
/// the index of the target frequency, which has been stored in the fft controller.
double sumPowerAt(double fIndex, Float64List spectrum) {
  List signalRange = spectrum.sublist(fIndex.floor() - 2,
      fIndex.toInt() + 3); // 3 is arbitrary. creates a range of 6 points
  double signalPower = signalRange.fold(0, (i, j) => i + j);
  return signalPower;
}

/// finds the index of the largest peak in a list. (highest dB value)
/// This is not guaranteed to be the desired signal.
int indexOfPeak(Float64List spectrum) {
  int peakPoint = spectrum.indexOf(
      spectrum.reduce((spectrum, next) => spectrum > next ? spectrum : next));
  return peakPoint;
}

/// finds index of the lowest dB value in the spectrum.
int indexOfFloor(Float64List spectrum) {
  int floorPoint = spectrum.indexOf(
      spectrum.reduce((spectrum, next) => spectrum < next ? spectrum : next));
  return floorPoint;
}

List<FlSpot> getDataPoints(Float64List curr) {
  // print('getDataPoints invoked'); // debugging
  if (curr.isEmpty) {
    return const [FlSpot(0, 0)];
  }
  // curr = curr.sublist(0, indexFromFreq(20001));
  // print('sublisted to only relevant points');
  // returns list of FlSpot objects given list of integers so they can be plotted
  List<FlSpot> dataPoints = [];
  for (var i = 0; i < curr.length; i++) {
    dataPoints
        .add(FlSpot((i * 20000 / curr.length), log10(curr[i].toDouble())));
  }
  return dataPoints;
}

/// truncates a double to 2 decimal places, mostly for readability.
double truncate(double value) {
  return (value * 100).round() / 100;
}

double freqFromIndex(num index) {
  return (index * 44100.0 / (currentView.value.fourierResponse.length - 1) / 2);
}

int indexFromFreq(num freq) {
  int size = currentView.value.fourierResponse.length;
  // int index = (freq * 2 * (size) / 44100).round();
  int index = (size / 20001 * freq).toInt();
  // print('index of $freq = $index');
  return index;
}

/// base 10 log function
double log10(double x) {
  return log(x) / log(10);
}
