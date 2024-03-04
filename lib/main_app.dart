// ignore_for_file: avoid_print, prefer_final_fields, prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:audiotestproject/components/controls/controlbar.dart';
import 'package:audiotestproject/components/controls/playbutton.dart';
import 'package:audiotestproject/components/plotting/power_spectrum_vis.dart';
import 'package:provider/provider.dart';
import 'components/data/globals.dart';
import 'package:flutter/material.dart';
import 'package:audiotestproject/components/controls/sidebar.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key, title});
  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with SingleTickerProviderStateMixin {
  late TabController tabbarcontroller;
  // bool _customTileExpanded = true;

  @override
  void initState() {
    super.initState();
    tabbarcontroller = TabController(length: 2, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    tabbarcontroller.dispose();
    super.dispose();
  }

  void onTap() {
    setState(() {
      tabbarcontroller.index = 0;
      tabbarcontroller.animateTo(0);
    });
  }

  /* ---- build the widget UI ---- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text('Device Microphone Tester'),
        toolbarHeight: 40,
        // bottom: ,
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Column(children: [
          Container(
            color: Color.fromRGBO(103, 186, 124, 1),
            height: 120,
            child: ListView(
              // TODO: re implement. bad UI
              scrollDirection: Axis.horizontal,
              physics: ClampingScrollPhysics(),

              /// List of controls in the toolbar
              children: [
                SettingsBorder(
                    title: 'Frequency Controls', child: FrequencyControls()),
                SettingsBorder(title: 'Volume Controls', child: VolumeSlider()),
                SettingsBorder(
                    title: 'Signal Controls', child: SignalControls()),
                SettingsBorder(
                    title: 'Device Selectors', child: DeviceSelectors()),
                PlayButton(),
              ],
            ),
          ),
          ChangeNotifierProvider(
            create: (context) => currentView,
            child: Row(
              // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder(
                    valueListenable: currentView,
                    builder:
                        (BuildContext context, currentView, Widget? child) {
                      print('rebuilt');
                      return Container(
                          width: MediaQuery.of(context).size.width - 300,
                          alignment: Alignment.topRight,
                          child: spectrumIsLoaded.value
                              ? SpectrumRender()
                              : Padding(padding: EdgeInsets.all(0)));
                    }),
                // ValueListenableBuilder(
                //     valueListenable: currentView,
                //     builder: (context, currentView, snapshot) {
                //       return SideBar();
                //     }),
                SideBar(),
              ],
            ),
          )
          // TabBar(
          //   controller: tabbarcontroller,
          //   tabs: [
          //     Tab(
          //       text: 'Signal',
          //     ),
          //     Tab(
          //       text: 'Power Spectrum',
          //     ),
          //   ],
          // ),
          // Expanded(
          //   child: TabBarView(
          //     controller: tabbarcontroller,
          //     viewportFraction: 1.0,
          //     children: [
          //       ListenableBuilder(
          //           listenable: signaldata,
          //           builder: (BuildContext context, Widget? child) {
          //             return SignalRender();
          //           }),
          //       ListenableBuilder(
          //           listenable: fftc,
          //           builder: (BuildContext context, Widget? child) {
          //             return SNRRender();
          //           }),
          //     ],
          //   ),
          // ),
        ]),
      ),
    );
  }
}
