import 'package:audiotestproject/components/controls/saving.dart';

import '/main_app.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  final title = 'Tone Generator';

  @override
  MyAppState createState() {
    return MyAppState();
  }
}

class MyAppState extends State<MyApp> {
  final title = 'Tone Generator';

  @override
  void initState() {
    super.initState();
    appInitCheckFile(); // get directories on app start
  }
  // root
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 7, 99, 7)),
        useMaterial3: true,
      ),
      home: MainApp(title: title),
    );
  }
}
