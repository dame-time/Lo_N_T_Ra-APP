import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionChecker {
  Future<void> checkPermissions(BuildContext context) async {
    final statuses = await [
      Permission.location,
      Permission.storage,
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();

    statuses.forEach((permission, status) {
      if (permission == Permission.bluetooth &&
              status != PermissionStatus.granted ||
          permission == Permission.bluetoothConnect &&
              status != PermissionStatus.granted ||
          permission == Permission.bluetoothScan &&
              status != PermissionStatus.granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Permission ${permission.toString().substring(11)} is not granted!\nApp will not work!'),
          ),
        );
        openAppSettings();
      } else if (status != PermissionStatus.granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Permission ${permission.toString().substring(11)} is not granted!'),
          ),
        );
      }
    });
  }
}
