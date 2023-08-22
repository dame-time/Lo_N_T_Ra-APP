import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothController {
  late final StreamSubscription<List<ScanResult>> subscription;

  void startScanning({Function? onComplete}) {
    if (FlutterBluePlus.isScanningNow) return;
    try {
      FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 3),
        androidUsesFineLocation: false,
      );
    } catch (e) {
      print(prettyException("Error: ", e));
    }

    // Schedule a call to the onComplete function after the timeout
    if (onComplete != null) {
      Future.delayed(
          const Duration(seconds: 10), onComplete as FutureOr Function()?);
    }
  }

  void subscribe({Function(List<ScanResult>)? onResults}) {
    subscription = FlutterBluePlus.scanResults.listen(
      (results) {
        if (onResults != null) {
          onResults(results);
        }
      },
    );
  }

  void stopScanning() {
    FlutterBluePlus.stopScan();
  }

  Future<void> turnOn() async {
    await FlutterBluePlus.turnOn();
  }

  Future<void> turnOff() async {
    await FlutterBluePlus.turnOff();
  }

  Future<bool> isBTOn() {
    return FlutterBluePlus.isOn;
  }

  Future<List<BluetoothDevice>> getConnectedDevices() async {
    return FlutterBluePlus.connectedSystemDevices;
  }

  void cancelSubscription() {
    subscription.cancel();
  }

  Future<bool> connect(BluetoothDevice device) async {
    try {
      await device.connect(
        timeout: const Duration(seconds: 30), // Connection timeout
        autoConnect: true, // Automatically reconnect if disconnected
      );
      print('Connected to ${device.localName}');

      return true;
    } catch (e) {
      print('Failed to connect to ${device.localName}: $e');
      // TODO: Handle connection failure
    }

    return false;
  }

  String prettyException(String prefix, dynamic e) {
    if (e is FlutterBluePlusException) {
      return "$prefix ${e.errorString}";
    } else if (e is PlatformException) {
      return "$prefix ${e.message}";
    }
    return prefix + e.toString();
  }

  // Additional functionalities can be added as needed.
}
