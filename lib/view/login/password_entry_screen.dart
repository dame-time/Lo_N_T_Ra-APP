import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lo_n_t_ra/controller/BT/bluetooth_controller.dart';
import 'package:lo_n_t_ra/view/communication/lora_device_search_screen.dart';

class PasswordEntryScreen extends StatefulWidget {
  final BluetoothDevice device;

  const PasswordEntryScreen({
    Key? key,
    required this.device,
  }) : super(key: key);

  @override
  PasswordEntryScreenState createState() => PasswordEntryScreenState();
}

class PasswordEntryScreenState extends State<PasswordEntryScreen> {
  TextEditingController passwordController = TextEditingController();
  FocusNode passwordFocusNode = FocusNode();
  bool showPassword = false;

  void disconnectDevice() async {
    await widget.device.disconnect();
  }

  @override
  void initState() {
    super.initState();
    passwordFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    passwordFocusNode.dispose();
    super.dispose();
  }

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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                disconnectDevice(); // Your disconnection method
                Navigator.pop(context); // Navigate back
              },
            ),
            flexibleSpace: const FlexibleSpaceBar(
              title: Text(
                'Enter Password',
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
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30.0,
                      ),
                      child: TextField(
                        controller: passwordController,
                        focusNode: passwordFocusNode,
                        obscureText: !showPassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: passwordFocusNode.hasFocus
                                ? const BorderSide()
                                : BorderSide
                                    .none, // Show border only when focused
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                        style: const TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        String password = passwordController.text;
                        try {
                          const String serviceUUID =
                              "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
                          const String characteristicUUID =
                              "beb5483e-36e1-4688-b7f5-ea07361b26a8";

                          await widget.device.requestMtu(36);

                          final service = await widget.device
                              .discoverServices()
                              .then((services) {
                            return services.firstWhere(
                                (serv) => serv.uuid.toString() == serviceUUID);
                          });

                          final characteristic =
                              service.characteristics.firstWhere(
                            (char) =>
                                char.uuid.toString() == characteristicUUID,
                          );

                          var key = utf8.encode("progetto-sistemi-operativi");
                          var bytes = utf8.encode(password);
                          var hmacSha256 = Hmac(sha256, key);
                          var digest = hmacSha256.convert(bytes);

                          final message = digest.bytes;

                          await characteristic.write(message, timeout: 30);

                          // Read from the characteristic to get the acknowledgment
                          var ack = await characteristic.read(timeout: 30);
                          String ackMessage = utf8.decode(ack);

                          if (ackMessage == "ACK") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoRaDeviceSearchScreen(
                                  bluetoothController: BluetoothController(),
                                  device: widget.device,
                                ),
                              ),
                            );
                          } else if (ackMessage == "NACK") {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Wrong Password!",
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Unable to communicate with device, try again!",
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "An error occurred while sending the message!",
                              ),
                            ),
                          );

                          print(
                            "An error occurred while sending the message: $e",
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 5,
                        backgroundColor: Colors.green, // background color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: const Text(
                        'Submit',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: showPassword,
                        onChanged: (value) {
                          setState(() {
                            showPassword = value ?? false;
                          });
                        },
                      ),
                      const Text(
                        'Show Password',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
