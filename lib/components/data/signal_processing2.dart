import 'dart:typed_data';
import 'dart:math';

/// reference page to check my own THD, SNR, SFDR calculations
/// copied and partially translated from C++ code. not used in app

/// long calculation page for finding SINAD, THD, SFDR values from the fft output.
/// params:
/// spectrum = power spectrum of transform. list of magnitudes. size is relative to input length
/// SamplingRate = sampling rate
/// checkBW = seems like the frequency range taken into consideration. should be 20000 - 20 = 19980
({double SFDR, double SINAD, double THD}) calcSinadThd(
    Float64List spectrum, double samplingRate, double checkBW) {
  // spectrum has already been reduced to only magnitudes
  // lists to store calculated powers later
  List<double> spectrumPowers = List<double>.filled(spectrum.length, 0);
  List<double> spectrumPowerLogs = List<double>.filled(spectrum.length, 0);

  int i; // ?
  double binWidth = (samplingRate /
      spectrum.length); // Resolution >> fft bin width (resolution of fft)
  int indexMin = (200 ~/ binWidth) -
      1; // Lower bound index for interested frequency. 200Hz is user defined?
  if (indexMin < 0) indexMin = 0; // cannot be negative, no less than DC
  int idx_H = ((samplingRate - checkBW) ~/ binWidth) -
      1; // upper bound index for interested frequency
  int signalRange = (checkBW ~/
      binWidth); // the index range for Signal Power Computation, calculated from zero.
  int iPowerMax = 0;
  double peakPower = -200;
  double PxxMin = 0.0;
  double PxxMinDec = 0.0;
  double Psig = 0.0;
  double Ptotal = 0.0;
  double Pnoise = 0.0;
  double Worst_Spur = -200;
  double Worst_Spur2 = -200;
  double Worst_Spur3 = -200;
  double Worst_Spur4 = -200;
  double Worst_Spur5 = -200;
  int Worst_Spur_I = 0;
  int Worst_Spur2_I = 0;
  int Worst_Spur3_I = 0;
  int Worst_Spur4_I = 0;
  int Worst_Spur5_I = 0;
  double Pspur = 0.0;
  int min_idx;

  // Compute the power in Frequency domain and take the log
  // for each point in the power spectrum, squares the amplitude to get the power. also records their log values
  for (i = 0; i < spectrum.length; i++) {
    spectrumPowers[i] = pow(spectrum[i], 2).toDouble();
    spectrumPowerLogs[i] =
        10 * log10(spectrumPowers[i]); // 10 * log10 of the magnitude at ii
  }

  // find the maximum and min value
  for (i = indexMin; i <= idx_H; i++) {
    Ptotal += spectrumPowers[i];
    if (spectrumPowerLogs[i] > peakPower) {
      peakPower = spectrumPowerLogs[i];
      iPowerMax = i;
    }
    if (spectrumPowerLogs[i] < PxxMin) {
      PxxMin = spectrumPowerLogs[i];
    }
  }
  PxxMinDec = pow(10, PxxMin / 10)
      .toDouble(); // min power in decibels. ?? 10^(pmin / 10)?

  // Compute Signal Power
  min_idx = ((iPowerMax - signalRange) > indexMin)
      ? (iPowerMax - signalRange)
      : indexMin; // pointless check?
  for (i = min_idx; i <= iPowerMax + signalRange; i++) {
    Psig += spectrumPowers[i];
    spectrumPowerLogs[i] = PxxMin; // ?
    spectrumPowers[i] = PxxMinDec; // ?
  }

  // Find the index of the worst spur
  for (i = indexMin; i <= idx_H; i++) {
    if (spectrumPowerLogs[i] > Worst_Spur) {
      print('first harmonic: $i');
      Worst_Spur = spectrumPowerLogs[i];
      Worst_Spur_I = i;
    }
  }
  // Compute the worst spur power
  for (i = Worst_Spur_I - 3; i <= Worst_Spur_I + 3; i++) {
    if (i < 0) i = 0;
    Pspur += spectrumPowers[i];
    spectrumPowerLogs[i] = PxxMin;
    spectrumPowers[i] = PxxMinDec;
  }
  // Find the Second worst spur
  for (i = indexMin; i <= idx_H; i++) {
    if (spectrumPowerLogs[i] > Worst_Spur2) {
      print('second harmonic: $i');
      Worst_Spur2 = spectrumPowerLogs[i];
      Worst_Spur2_I = i;
    }
  }
  // accumulate the worst spur power
  for (i = Worst_Spur2_I - 3; i <= Worst_Spur2_I + 3; i++) {
    if (i < 0) i = 0;
    Pspur += spectrumPowers[i];
    spectrumPowerLogs[i] = PxxMin;
    spectrumPowers[i] = PxxMinDec;
  }
  // Find the third worst spur
  for (i = indexMin; i <= idx_H; i++) {
    if (spectrumPowerLogs[i] > Worst_Spur3) {
      print('third harmonic: $i');
      Worst_Spur3 = spectrumPowerLogs[i];
      Worst_Spur3_I = i;
    }
  }
  // accumulate the worst spur power
  for (i = Worst_Spur3_I - 3; i <= Worst_Spur3_I + 3; i++) {
    if (i < 0) i = 0;
    Pspur += spectrumPowers[i];
    spectrumPowerLogs[i] = PxxMin;
    spectrumPowers[i] = PxxMinDec;
  }
  // Find the forth worst spur
  for (i = indexMin; i <= idx_H; i++) {
    print('fourth harmonic: $i');
    if (spectrumPowerLogs[i] > Worst_Spur4) {
      Worst_Spur4 = spectrumPowerLogs[i];
      Worst_Spur4_I = i;
    }
  }
  // accumulate the worst spur power
  for (i = Worst_Spur4_I - 3; i <= Worst_Spur4_I + 3; i++) {
    if (i < 0) i = 0;
    Pspur += spectrumPowers[i];
    spectrumPowerLogs[i] = PxxMin;
    spectrumPowers[i] = PxxMinDec;
  }
  // Find the fifth worst spur
  for (i = indexMin; i <= idx_H; i++) {
    if (spectrumPowerLogs[i] > Worst_Spur5) {
      print('fifth harmonic: $i');
      Worst_Spur5 = spectrumPowerLogs[i];
      Worst_Spur5_I = i;
    }
  }
  // accumulate the worst spur power
  for (i = Worst_Spur5_I - 3; i <= Worst_Spur5_I + 3; i++) {
    if (i < 0) i = 0;
    Pspur += spectrumPowers[i];
  }

  Pnoise = Ptotal - Psig; // compute the noise power
  double SINAD = 10 * log10(Psig / Pnoise); // compute SINAD
  double SFDR = peakPower - Worst_Spur; // compute SFDR
  double THD = sqrt(Pspur / Psig); //compute THD

  spectrumPowers.clear(); // necessary?
  spectrumPowerLogs.clear(); // necessary?
  return (SINAD: SINAD, SFDR: SFDR, THD: THD);
}

double log10(double x) {
  return log(x) / log(10);
}


