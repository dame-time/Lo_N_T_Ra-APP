import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lo_n_t_ra/controller/BT/bluetooth_controller.dart';
import 'package:lo_n_t_ra/view/login/password_entry_screen.dart';

class DeviceListScreen extends StatefulWidget {
  final List<ScanResult> devices;
  final BluetoothController bluetoothController;

  const DeviceListScreen({
    Key? key,
    required this.devices,
    required this.bluetoothController,
  }) : super(key: key);

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  bool isLoading = false;

  void onTapDevice(BuildContext context, BluetoothDevice device) {
    print("pairing with ${device.localName}");
    setState(() {
      isLoading = true; // Start loading
    });

    widget.bluetoothController.connect(device).then((value) {
      setState(() {
        isLoading = false;
      });

      if (!value) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Unable to connect to device, try again!",
            ),
          ),
        );

        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PasswordEntryScreen(device: device),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
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
                    'Select a Device',
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
                      title: widget.devices[index].device.localName == ""
                          ? Text(
                              widget.devices[index].device.remoteId.str,
                              style: const TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          : Text(
                              widget.devices[index].device.localName,
                              style: const TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                      onTap: () =>
                          onTapDevice(context, widget.devices[index].device),
                    );
                  },
                  childCount: widget.devices.length,
                ),
              ),
            ],
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5), // Blur effect
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
