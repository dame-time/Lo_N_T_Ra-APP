import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lo_n_t_ra/model/message.dart';

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
  final List<Message> _messages = [];

  void _sendMessage() async {
    final text = _controller.text.trim();

    Message myMessage = Message(
      text: text,
      isSender: true,
    );

    if (text.isNotEmpty) {
      setState(() {
        _messages.add(myMessage);
      });
      _controller.clear();
      // TODO: Implement sending message to the device
    }

    const String serviceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
    const String characteristicUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

    await widget.device.requestMtu(text.length);

    final service = await widget.device.discoverServices().then((services) {
      return services.firstWhere((serv) => serv.uuid.toString() == serviceUUID);
    });

    final characteristic = service.characteristics.firstWhere(
      (char) => char.uuid.toString() == characteristicUUID,
    );

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
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'assets/bg.jpg'), // Replace with your background image
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[_messages.length - index - 1];
                  return Align(
                    alignment: message.isSender
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: message.isSender ? Colors.green : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        message.text,
                        style: const TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(
                            fontFamily: 'Fredoka',
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Enter your message...',
                            border: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 15),
                          ),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.green[900],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
