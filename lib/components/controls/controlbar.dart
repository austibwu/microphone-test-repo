// ignore_for_file: avoid_print, prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'dart:async';
import 'package:audiotestproject/components/data/globals.dart';
import 'package:audiotestproject/components/audio_out/wavegenerator/wave_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';

/// child widgets defined below are directly added to mainapp.

/// frequency controls
/// TODO: correctly implement controls for step# input, chirp controls.
class FrequencyControls extends StatefulWidget {
  const FrequencyControls({
    super.key,
  });

  @override
  State<FrequencyControls> createState() => _FrequencyControlsState();
}

class _FrequencyControlsState extends State<FrequencyControls> {
  bool checked = true;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // const Padding(padding: EdgeInsets.all(10)),
              SizedBox(
                width: 50,
                height: 30,
                child: TextField(
                  cursorHeight: 15,
                  maxLength: 4,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  // only numbers, up to 4 digits // TODO: change, user should be able to input to higher than 9999Hz
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp('[0-9]{0,4}')),
                  ],
                  decoration: const InputDecoration(
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    labelStyle: TextStyle(fontSize: 14),
                    labelText: '500',
                    counterText: "",
                  ),
                  onChanged: (freq) {
                    if (freq == '') {
                      return;
                    }
                    waveMaker.fNought = int.parse(freq);
                  },
                ),
              ),
              const Text('Hz'),
              Row(
                children: [
                  Text('  to   ',
                      style: (checked)
                          ? TextStyle(color: Color.fromARGB(255, 54, 136, 71))
                          : null),
                  AbsorbPointer(
                    absorbing: checked,
                    child: SizedBox(
                      width: 50,
                      height: 30,
                      child: TextField(
                        style: (checked)
                            ? TextStyle(color: Color.fromARGB(255, 54, 136, 71))
                            : null,
                        cursorHeight: 15,
                        maxLength: 4,
                        maxLengthEnforcement: MaxLengthEnforcement.enforced,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(
                              RegExp('[0-9]{0,4}')),
                        ],
                        decoration: const InputDecoration(
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                          labelStyle: TextStyle(fontSize: 14),
                          labelText: '500',
                          counterText: "",
                        ),
                        onChanged: (freq) {
                          if (freq == '') {
                            return;
                          }
                          waveMaker.fEnd = int.parse(freq);
                        },
                      ),
                    ),
                  ),
                  Text(
                    'Hz',
                    style: (checked)
                        ? TextStyle(color: Color.fromARGB(255, 54, 136, 71))
                        : null,
                  ),
                ],
              ),
            ],
          ),
          Padding(padding: EdgeInsets.all(10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: .6,
                child: Checkbox(
                  visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                  checkColor: Colors.white,
                  value: checked,
                  onChanged: (value) => setState(() {
                    checked = value!;
                  }),
                ),
              ),
              const Text('single tone'),
              Padding(padding: EdgeInsets.only(left: 20)),
              Text('# steps:',
                  style: (checked)
                      ? TextStyle(color: Color.fromARGB(255, 54, 136, 71))
                      : null),
              Text(waveMaker.steps.toString(),
                  style: (checked)
                      ? TextStyle(color: Color.fromARGB(255, 54, 136, 71))
                      : null),
            ],
          ),
        ],
      ),
    );
  }
}

/// widget containing controls for characteristics of the waveform (bitdepth, wave shape, duration)
class SignalControls extends StatefulWidget {
  const SignalControls({
    super.key,
  });

  @override
  State<SignalControls> createState() => _SignalControlsState();
}

class _SignalControlsState extends State<SignalControls> {
  SignalType defaultSignal = SignalType.tone;
  BitDepth defaultDepth = BitDepth.depth16Bit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 190,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(style: TextStyle(), 'wave type:'),
                Transform.scale(
                  scale: 0.8,
                  child: SizedBox(
                    height: 20,
                    child: DropdownButtonHideUnderline(
                      child: ButtonTheme(
                        padding: EdgeInsets.all(0),
                        buttonColor: Colors.white,
                        layoutBehavior: ButtonBarLayoutBehavior.constrained,
                        alignedDropdown: true,
                        child: DropdownButton<SignalType>(
                          // isExpanded: true,
                          isDense: true,
                          items: SignalType.values
                              .map<DropdownMenuItem<SignalType>>(
                                  (SignalType depthselection) {
                            return DropdownMenuItem<SignalType>(
                              value: depthselection,
                              child: Text(depthselection.label),
                            );
                          }).toList(),
                          value: defaultSignal,
                          onChanged: (selection) {
                            setState(() {
                              defaultSignal = selection ?? SignalType.tone;
                              waveMaker.audioType =
                                  selection?.place ?? 0; // TODO: will fix later
                              waveMaker.isSweep = selection == SignalType.sweep;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(style: TextStyle(), 'bit depth:'),
                Transform.scale(
                  scale: .8,
                  child: DropdownButtonHideUnderline(
                    child: ButtonTheme(
                      layoutBehavior: ButtonBarLayoutBehavior.constrained,
                      alignedDropdown: true,
                      child: DropdownButton<BitDepth>(
                        isDense: true,
                        items: bitDepthsList.entries
                            .map<DropdownMenuItem<BitDepth>>((entry) {
                          return DropdownMenuItem<BitDepth>(
                            value: entry.value,
                            child: Text(entry.key),
                          );
                        }).toList(),
                        value: defaultDepth,
                        onChanged: (s) {
                          setState(() {
                            defaultDepth = s ?? BitDepth.depth16Bit;
                            waveMaker.bitDepth = s ?? BitDepth.depth8Bit;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            DurationSlider(),
          ],
        ));
  }
}

// TODO: add control for signal magnitude.

/// volume slider widget that controls PLATFORM DEVICE volume.
class VolumeSlider extends StatefulWidget {
  const VolumeSlider({
    super.key,
  });

  @override
  State<VolumeSlider> createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<VolumeSlider> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.volume_up, color: const Color.fromARGB(255, 39, 39, 39)),
        Slider(
          value: waveMaker.volume,
          label: waveMaker.volume.toString(),
          onChanged: (volume) {
            FlutterVolumeController.setMute(
                false); // disables mute if 'mute' is enabled on system
            FlutterVolumeController.setVolume(
                volume); // keeps in sync to device volume
            waveMaker.volume = volume;
            setState(() => {});
          },
        ),
      ],
    );
  }
}

/// duration slider widget. should change to allow for more granular selection of time, and longer than 6 seconds? 
/// if longer than 6 seconds, audio data will be massive.
class DurationSlider extends StatefulWidget {
  const DurationSlider({
    super.key,
  });

  @override
  State<StatefulWidget> createState() => DurationSliderState();
}

class DurationSliderState extends State<DurationSlider> {
  final OverlayPortalController _tooltipController = OverlayPortalController();

  final _link = LayerLink();
  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
  }

  /// width of the button after the widget rendered
  double? buttonWidth; // not entirely sure what this does

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('duration:      '),
        CompositedTransformTarget(
          link: _link,
          child: OverlayPortal(
            controller: _tooltipController,
            child: TextButton(
              style: ButtonStyle(
                shape: MaterialStateProperty.all(ContinuousRectangleBorder(
                    borderRadius: BorderRadius.circular(9))),
                // backgroundColor: MaterialStateProperty<Colors.green>,
                minimumSize: MaterialStatePropertyAll(Size(30, 32)),
                fixedSize: MaterialStateProperty.all(Size(30, 10)),
                backgroundColor: MaterialStatePropertyAll(Colors.green),
                textStyle: MaterialStatePropertyAll(
                  TextStyle(
                    fontSize: 13,
                    height: .6,
                    // color: Colors.black,
                  ),
                ),
                overlayColor: MaterialStateProperty.all(Colors.transparent),
                padding: MaterialStateProperty.all(EdgeInsets.zero),
              ),
              onPressed: () {
                buttonWidth = context.size?.width;
                _tooltipController.toggle();
                setState(() {
                  // print(x.duration);
                });
              },
              child: Text(
                style: TextStyle(
                  fontSize: 13,
                  height: .6,
                  // color: Colors.black,
                ),
                waveMaker.duration.toInt().toString(),
                // style: TextStyle(color: Colors.black),
              ),
            ),
            overlayChildBuilder: (BuildContext context) {
              return CompositedTransformFollower(
                link: _link,
                targetAnchor: Alignment.bottomLeft,
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: Container(
                    padding: EdgeInsets.all(3),
                    decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 5,
                            blurRadius: 7,
                            offset: Offset(0, 3), // changes position of shadow
                          ),
                        ],
                        color: Colors.white,
                        borderRadius: BorderRadius.all(
                          Radius.circular(5.5),
                        )),
                    // color: Colors.white,
                    width: 220,
                    height: 30,
                    child: Row(
                      children: [
                        Text('1'),
                        Slider(
                          value: waveMaker.duration,
                          min: 1,
                          max: 6,
                          divisions: 5,
                          // label: x.duration.toInt().toString(),
                          onChanged: (duration) => setState(() {
                            waveMaker.duration = duration;
                            print(waveMaker.duration);
                          }),
                          onChangeEnd: (o) {
                            Timer(Duration(milliseconds: 60), () {
                              // just for UX purposes
                              _tooltipController.toggle();
                            });
                          },
                        ),
                        Text('6'),
                      ],
                    ),
                  ), //width: _buttonWidth
                ),
              );
            },
          ),
        ),
        Text('  s  '),
      ],
    );
  }

  void onTap() {
    buttonWidth = context.size?.width;
    _tooltipController.toggle();
  }
}

/// place holder widgets for user to choose i/o devices.
/// I do not know how to expose this to the user. requires C++ plugin support.
class DeviceSelectors extends StatefulWidget {
  const DeviceSelectors({
    super.key,
  });

  @override
  State<DeviceSelectors> createState() => _DeviceSelectorsState();
}

class _DeviceSelectorsState extends State<DeviceSelectors> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // Padding(padding: const EdgeInsets.all(5)),
        Row(
          children: [
            const Text('Speaker Device:'),
            DropdownButtonHideUnderline(
              child: ButtonTheme(
                alignedDropdown: true,
                child: DropdownButton<String>(
                  hint: Text('N/A'),
                  isDense: true,
                  items: [
                    DropdownMenuItem<String>(
                        value: 'doesn\'t work',
                        child: Text('doesn\'t work yet'))
                  ],
                  // value: 'doesn\'t work yet', // will fix later
                  onChanged: (selection) {
                    setState(() {});
                  },
                ),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Microphone Device:'),
            DropdownButtonHideUnderline(
              child: ButtonTheme(
                alignedDropdown: true,
                child: DropdownButton<String>(
                  hint: Text('N/A'),
                  isDense: true,
                  items: [
                    DropdownMenuItem<String>(
                        value: 'doesn\'t work',
                        child: Text('doesn\'t work yet'))
                  ],
                  // value: 'doesn\'t work yet', // will fix later
                  onChanged: (selection) {
                    setState(() {});
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// custom widget for the settings menu categories.
class SettingsBorder extends StatelessWidget {
  final Widget child;
  final String title;

  const SettingsBorder({super.key, required this.child, required this.title});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
          height: 100,
          padding: const EdgeInsets.all(10.0),
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.blueGrey,
            ),
            borderRadius: BorderRadius.all(
              Radius.circular(8),
            ),
          ),
          child: child),
      Positioned(
        left: 5,
        top: 0,
        child: Container(
          height: 24,
          margin: EdgeInsets.only(bottom: 10, left: 12, right: 10),
          color: Color.fromRGBO(103, 186, 124, 1),
          child: Text(
            ' $title ',
            style: TextStyle(color: Colors.blueGrey, fontSize: 12),
          ),
        ),
      ),
    ]);
  }
}
