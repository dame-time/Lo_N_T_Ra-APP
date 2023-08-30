import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lo_n_t_ra/controller/BT/bluetooth_controller.dart';
import 'package:lo_n_t_ra/view/login/device_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceSearchScreen extends StatefulWidget {
  const DeviceSearchScreen({super.key});

  @override
  DeviceSearchScreenState createState() => DeviceSearchScreenState();
}

class DeviceSearchScreenState extends State<DeviceSearchScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  final BluetoothController _bluetoothController = BluetoothController();
  List<ScanResult> _devices = [];
  bool _isSearching = false;
  bool _isBTOn = false;
  Timer? _bluetoothPollingTimer;

  Future<void> _clearSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }

  @override
  void initState() {
    super.initState();
    _clearSharedPreferences();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    WidgetsBinding.instance.addObserver(this);

    _bluetoothController.subscribe(
      onResults: (results) {
        setState(() {
          _devices = results;
        });
      },
    );

    _bluetoothController.turnOn();
    _bluetoothController.isBTOn().then((value) {
      setState(() {
        _isBTOn = value;
      });
      if (value) _startSearch();
    });
    // _bluetoothPollingTimer =
    //     Timer.periodic(const Duration(seconds: 10), (timer) {
    //   _checkBluetoothState();
    // });
  }

  void _checkBluetoothState() async {
    bool isOn = await _bluetoothController.isBTOn();
    if (!isOn) {
      await _bluetoothController.turnOn();
      isOn = await _bluetoothController.isBTOn();
    }
    setState(() {
      _isBTOn = isOn;
    });

    if (isOn) {
      _startSearch();
    }
  }

  void _startSearch() {
    if (!_isBTOn) return;

    setState(() {
      _isSearching = true;
      _controller.reset();
      _controller.repeat();
    });
    _devices.clear();
    _bluetoothController.startScanning(
      onComplete: () {
        _stopSearchAndNavigate();
      },
    );
  }

  void _stopSearchAndNavigate() {
    setState(() {
      _isSearching = false;
    });
    _bluetoothController.stopScanning();
    _controller.reset();
    _controller.stop();

    // Check if the devices found are greater than one
    if (_devices.length > 1) {
      // Navigate to the next page and pass the list of devices
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DeviceListScreen(
            devices: _devices,
            bluetoothController: _bluetoothController,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bluetoothPollingTimer?.cancel();
    // _bluetoothController.cancelSubscription();
    _bluetoothController.stopScanning();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            _checkBluetoothState();
            _isBTOn ? _startSearch : _bluetoothController.turnOn;
          },
          backgroundColor: Colors.green,
          label: _isBTOn
              ? const Text(
                  "Search Devices...",
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                )
              : const Text(
                  "Turn On BT",
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
              flexibleSpace: const FlexibleSpaceBar(
                title: Text(
                  'Scan Devices',
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
                  if (_isSearching)
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
