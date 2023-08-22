import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class LoRaChatScreen extends StatefulWidget {
  final String deviceName;
  final BluetoothDevice device;

  const LoRaChatScreen({
    Key? key,
    required this.deviceName,
    required this.device,
  }) : super(key: key);

  @override
  LoRaChatScreenState createState() => LoRaChatScreenState();
}

class LoRaChatScreenState extends State<LoRaChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = [];

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _messages.add(text);
      });
      _controller.clear();
      // TODO: Implement sending message to the device
    }

    const String serviceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
    const String characteristicUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

    await widget.device.requestMtu(150);

    final service = await widget.device.discoverServices().then((services) {
      return services.firstWhere((serv) => serv.uuid.toString() == serviceUUID);
    });

    final characteristic = service.characteristics.firstWhere(
      (char) => char.uuid.toString() == characteristicUUID,
    );

    print(text);

    var bytes = utf8.encode(text);

    final message = bytes;

    await characteristic.write(message, timeout: 30);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deviceName),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    _messages[_messages.length - index - 1],
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                        hintText: 'Enter your message...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
