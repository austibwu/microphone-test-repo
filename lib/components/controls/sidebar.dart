// ignore_for_file: prefer_const_constructors, avoid_print

import 'package:audiotestproject/components/controls/saving.dart';
import 'package:flutter/material.dart';
import 'package:audiotestproject/components/data/globals.dart';
import 'package:audiotestproject/components/data/signal_processing.dart';
// import 'package:provider/provider.dart';

/// widget for the 'side bar' view on the app
/// TODO: does it need to be stateful?
class SideBar extends StatefulWidget {
  const SideBar({
    super.key,
  });

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  @override
  Widget build(BuildContext context) {
    List<Widget> savedTiles = createListTilesFromSaved();
    return Expanded(
      child: Container(
        height: MediaQuery.sizeOf(context).height - 160,
        color: Color.fromARGB(255, 124, 207, 160),
        child: ListView(
          physics: ClampingScrollPhysics(),
          children: [
            SideBarMenuTile(title: 'Sound out - summary', children: <Widget>[
              ListTile(
                  selectedColor: Color.fromARGB(255, 124, 207, 160),
                  subtitle: Text(
                      'Summary: generating ${outputWave.fNought}Hz tone of ${outputWave.bitDepth} bitdepth at ${outputWave.duration} seconds long.')),
            ]),
            ListenableBuilder(
                listenable: spectrumIsLoaded,
                builder: (context, snapshot) {
                  return Column(
                    children: [
                      IgnorePointer(
                        ignoring: !spectrumIsLoaded.value,
                        child: SideBarMenuTile(
                            title: 'Sound in - analysis summary',
                            children: <Widget>[
                              ListTile(
                                  subtitle: Text(spectrumIsLoaded.value
                                      ? calculateSNR(
                                          currentView.value.fourierResponse).toString()
                                      : '')),
                              ListTile(
                                  subtitle: Text(spectrumIsLoaded.value
                                      ? calculateSFDR(
                                          currentView.value.fourierResponse).toString()
                                      : '')),
                              ListTile(
                                  subtitle: Text(spectrumIsLoaded.value
                                      ? calculateTHD(
                                          currentView.value.fourierResponse).toString()
                                      : '')),
                            ]),
                      ),
                      IgnorePointer(
                        ignoring: !spectrumIsLoaded.value,
                        child: SideBarMenuTile(
                            title: 'Graph controls',
                            children: const <Widget>[
                              ListTile(
                                subtitle: GraphControlsWidget(),
                              ),
                            ]),
                      )
                    ],
                  );
                }),
            ListenableBuilder(
              listenable: storedLogNotifier,
              builder: (context, widget) {
                return SideBarMenuTile(
                  title: 'Saved', children: savedTiles,
                );
              }
            )
          ],
        ),
      ),
    );
  }
}

/// toggles the graph UI. not completed
class GraphControlsWidget extends StatefulWidget {
  final bool initiallyExpanded;

  const GraphControlsWidget({
    super.key,
    this.initiallyExpanded = false,
  });

  @override
  State<GraphControlsWidget> createState() => _GraphControlsWidgetState();
}

class _GraphControlsWidgetState extends State<GraphControlsWidget> {
  bool linetouch = true;
  bool showMarkers = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            Checkbox(
              value: linetouch,
              onChanged: (clicked) {
                ChartProvider.switchLineTouch();
                // print(clicked);
                setState(() {
                  // print(linetouch);
                  linetouch = clicked!;
                  // print(linetouch);
                });
              },
            ),
            Text('hover enabled'),
          ],
        ),
        Row(
          children: [
            Checkbox(
              value: showMarkers,
              onChanged: (clicked) {
                ChartProvider.showMarkers();
                // print(clicked);
                setState(() {
                  print(showMarkers);
                  showMarkers = clicked!;
                  // print(showMarkers);
                });
              },
            ),
            Text('show harmonic markers'),
          ],
        ),
        TextButton(
            onPressed: () {
              // Provider.of<ChartProvider>(context, listen: false)
              //     .switchYAxisUnits();
              ChartProvider.switchYAxisUnits();
            },
            child: Text('units')),
        Row(
          // below textbuttons are all placeholders.
          children: [
            TextButton(onPressed: () {}, child: Text('Turn off hover')),
            TextButton(onPressed: () {}, child: Text('Turn off hover')),
          ],
        ),
        TextButton(onPressed: () {}, child: Text('Turn off hover')),
        TextButton(onPressed: () {}, child: Text('Turn off hover'))
      ],
    );
  }
}

// custom widget wrapper to format the sidebar sections.
class SideBarMenuTile extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;

  const SideBarMenuTile({
    super.key,
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      collapsedBackgroundColor: Colors.green[700],
      // backgroundColor: Colors.green[700],
      title: Text(style: TextStyle(color: Colors.white), title),
      // subtitle: Text('Trailing expansion arrow icon'),
      children: children,
    );
  }
}
