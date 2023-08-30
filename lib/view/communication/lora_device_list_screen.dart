import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:lo_n_t_ra/controller/BT/bluetooth_controller.dart';
import 'package:lo_n_t_ra/view/communication/lora_chat_screen.dart';

class LoRaDeviceListScreen extends StatefulWidget {
  final List<String> devices;
  final BluetoothController bluetoothController;
  final BluetoothDevice bluetoothDevice;

  const LoRaDeviceListScreen({
    Key? key,
    required this.devices,
    required this.bluetoothController,
    required this.bluetoothDevice,
  }) : super(key: key);

  @override
  State<LoRaDeviceListScreen> createState() => _LoRaDeviceListScreen();
}

class _LoRaDeviceListScreen extends State<LoRaDeviceListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: false,
            expandedHeight: MediaQuery.of(context).size.height * 0.08,
            elevation: 50.0,
            shape: const ContinuousRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(100),
                bottomRight: Radius.circular(100),
              ),
            ),
            flexibleSpace: const FlexibleSpaceBar(
              title: Text(
                'Obtained Devices',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              centerTitle: true,
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return ListTile(
                  title: widget.devices[index] == ""
                      ? const Text(
                          "Unknown Device",
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : Text(
                          widget.devices[index].split("-")[0],
                          style: const TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoRaChatScreen(
                          deviceName: widget.devices[index],
                          device: widget.bluetoothDevice,
                        ),
                      ),
                    );
                  },
                );
              },
              childCount: widget.devices.length,
            ),
          ),
        ],
      ),
    );
  }
}
