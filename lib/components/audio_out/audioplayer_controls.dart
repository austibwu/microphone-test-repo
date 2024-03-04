// ignore_for_file: avoid_print

import 'package:audiotestproject/components/data/globals.dart';


/// can probably delete file

void disposefunc() async {
  print('dispose button pressed');
  await waveMaker.player.dispose();
  // await player.audioCache.clearAll();
  // setState(() => player = AudioPlayer());
}
