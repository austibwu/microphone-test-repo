// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:typed_data';
import 'package:audiotestproject/components/data/signal_processing.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:audiotestproject/components/data/globals.dart';

/// globals to be initialized when the app is first started.
late Directory appCacheDir;
late Directory appDocDir;
late File storageFile;

/// run on app start. checks if file exists. if not, creates it.
Future<void> appInitCheckFile() async {
  appCacheDir = await getApplicationCacheDirectory();
  appDocDir = await getApplicationDocumentsDirectory();
  storageFile = File('${appDocDir.path}/saved_spectrums.json');
  if (outputWave.filePath == '') {
    outputWave.filePath = '${appCacheDir.path}/wave_out.wav';
  }
  if (!await storageFile.exists()) {
    // file does not exist
    await storageFile.create();
  }
  // file exists, empty or not
  readFromFile();
}

/// Parse JSON file into list of objects representing past signal analyses
Future<List<dynamic>> readFromFile() async {
  String fileContents = await storageFile.readAsString();
  print('readfromfile');
  if (fileContents != '') {
    var jsonResponse = jsonDecode(fileContents);
    if (jsonResponse is List<dynamic>) {
      for (var item in jsonResponse) {
        print(item.runtimeType);
        try {
          var current = SpectrumData(
              item['fNought'],
              item['fEnd'],
              item['steps'],
              item['isSweep'],
              bitDepthsList[item['bitDepth']]!,
              item['duration'],
              Float64List.fromList(item['fourierResponse'].cast<double>()));
          storedLog.add(current);
        } catch (e) {
          print('error parsing json: $e');
        }
      }
    }
  }
  fileContents = '';
  print('storedLog read from file. length: ${storedLog.length}');
  return storedLog;
}

/// adds current spectrum view to list of spectrum views
void save(SpectrumData curr) {
  storedLog.add(curr);
  // print(storedLog); // for debugging
  writeToFile();
}

/// deletes the selected view from the list
void delete(SpectrumData curr) {
  storedLog.remove(curr);
  writeToFile();
}

/// updates the json file, then reads it. is it necessary to read it again?
void writeToFile() {
  storageFile.writeAsString(jsonEncode(storedLog), mode: FileMode.writeOnly);
  // TODO: update 'saved' widget view. key? change notifier?
}

/// generates the list of clickable widgets representing saved signals.
List<Widget> createListTilesFromSaved() {
  List<Widget> listTiles = [];
  print('storedLog length: ${storedLog.length}');
  for (var curr in storedLog) {
    listTiles.add(
      ListTile(
        subtitle: Text(curr.description()),
        trailing: IconButton(
            icon: const Icon(Icons.delete), onPressed: () => delete(curr)),
        onTap: () {
          // TODO: implement functions to update the spectrumRender() graph.
          updateCurrentView(curr);
        },
      ),
    );
  }
  if (listTiles.isEmpty) {
    listTiles.add(ListTile(title: Text('No saved signals'),
    trailing: TextButton(onPressed: () => createListTilesFromSaved(), child: Text('refresh')),));
  }
  return listTiles;
}
