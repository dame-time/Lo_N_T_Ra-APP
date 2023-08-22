import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lo_n_t_ra/view/splash_screen.dart';
import 'package:permission_handler/permission_handler.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  if (!Platform.isMacOS) {
    WidgetsFlutterBinding.ensureInitialized();
    await [
      Permission.location,
      Permission.storage,
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();

    runApp(const LoNTRa());
  } else {
    runApp(const LoNTRa());
  }
}

class LoNTRa extends StatelessWidget {
  const LoNTRa({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LoNTRa',
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const SplashScreen(),
    );
  }
}
