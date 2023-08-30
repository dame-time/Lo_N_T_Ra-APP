import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lo_n_t_ra/controller/BT/bluetooth_controller.dart';
import 'package:lo_n_t_ra/model/message_manager.dart';
import 'package:lo_n_t_ra/view/communication/lora_device_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoRaDeviceSearchScreen extends StatefulWidget {
  final BluetoothController bluetoothController;
  final BluetoothDevice device;

  const LoRaDeviceSearchScreen({
    super.key,
    required this.bluetoothController,
    required this.device,
  });

  @override
  LoRaDeviceSearchScreenState createState() => LoRaDeviceSearchScreenState();
}

class LoRaDeviceSearchScreenState extends State<LoRaDeviceSearchScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    MessageManager().startListeningForDevice(widget.device);

    WidgetsBinding.instance.addObserver(this);
    startSearch();
  }

  void startSearch() async {
    _controller.repeat(); // Start the animation
    // Wait for 3 seconds
    await Future.delayed(const Duration(seconds: 3));
    // Call the function to show connected peers
    String responseMessage = await showConnectedPeers();
    _controller.stop(); // Stop the animation
    _controller.reset();

    if (responseMessage.isNotEmpty) {
      List<String> peers = [];
      var results = responseMessage.split(";");
      for (var result in results) {
        setState(
          () {
            if (result.length > 1) peers.add(result);
          },
        );
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoRaDeviceListScreen(
            devices: peers,
            bluetoothController: widget.bluetoothController,
            bluetoothDevice: widget.device,
          ),
        ), // Define NextScreen according to your requirements
      );
    }
  }

  Future<void> _clearSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }

  // TODO: Call that on dispose or when the app gets closed also on the password screen do the same thing
  Future<bool> disconnectDevice() async {
    const String serviceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
    const String characteristicUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

    await widget.device.requestMtu(36);

    final service = await widget.device.discoverServices().then((services) {
      return services.firstWhere((serv) => serv.uuid.toString() == serviceUUID);
    });

    final characteristic = service.characteristics.firstWhere(
      (char) => char.uuid.toString() == characteristicUUID,
    );

    var bytes = utf8.encode("disconnect");

    final message = bytes;

    await characteristic.write(message, timeout: 30);
    await widget.device.disconnect();

    MessageManager().stopListeningForDevice(widget.device);

    return true;
  }

  Future<String> showConnectedPeers() async {
    const String serviceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
    const String characteristicUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

    await widget.device.requestMtu(36);

    final service = await widget.device.discoverServices().then((services) {
      return services.firstWhere((serv) => serv.uuid.toString() == serviceUUID);
    });

    final characteristic = service.characteristics.firstWhere(
      (char) => char.uuid.toString() == characteristicUUID,
    );

    var bytes = utf8.encode("R:");

    final message = bytes;

    await characteristic.write(message, timeout: 30);
    var response = await characteristic.read(timeout: 30);
    String responseMessage = utf8.decode(response);

    return responseMessage;
  }

  @override
  void dispose() {
    _clearSharedPreferences();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            startSearch();
          },
          backgroundColor: Colors.green,
          label: const Text(
            "Search LoRa Devices...",
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 5,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  disconnectDevice().then((_) {
                    int count = 0;
                    Navigator.popUntil(context, (route) {
                      return count++ ==
                          3; // Pop 3 times to go back to the previous previous previous screen
                    });
                  });
                },
              ),
              flexibleSpace: const FlexibleSpaceBar(
                title: Text(
                  'Scan LoRa Devices',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                centerTitle: true,
              ),
            ),
            SliverFillRemaining(
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  // if (_isSearching)
                  Center(
                    child: RadarAnimation(controller: _controller),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.25,
                    height: MediaQuery.of(context).size.height * 0.25,
                    child: Image.asset(
                      'assets/logo.png',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ));
  }
}

class RadarAnimation extends StatelessWidget {
  const RadarAnimation({Key? key, required this.controller}) : super(key: key);

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        CircleAnimation(controller: controller, begin: 0.0, end: 0.6),
        CircleAnimation(controller: controller, begin: 0.2, end: 0.8),
        CircleAnimation(controller: controller, begin: 0.4, end: 1.0),
      ],
    );
  }
}

class CircleAnimation extends StatelessWidget {
  CircleAnimation({
    Key? key,
    required AnimationController controller,
    required this.begin,
    required this.end,
  })  : animation = Tween<double>(begin: 0, end: 300).animate(
            CurvedAnimation(parent: controller, curve: Interval(begin, end))),
        super(key: key);

  final Animation<double> animation;
  final double begin;
  final double end;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          return Opacity(
            opacity: 1.0 - (animation.value / 300),
            child: Container(
              width: animation.value,
              height: animation.value,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green,
              ),
            ),
          );
        });
  }
}
