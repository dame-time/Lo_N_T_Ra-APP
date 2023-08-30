import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lo_n_t_ra/model/message.dart';
import 'package:lo_n_t_ra/model/message_manager.dart';

// TODO: In the previous screen, when connecting to the chat recoup all the messages and separate them by sender
// then just display those, plus all the new one in this screen
class LoRaChatScreen extends StatefulWidget {
  final String deviceName;
  final BluetoothDevice device;
  final List<String>? previousMessages;

  const LoRaChatScreen({
    Key? key,
    required this.deviceName,
    required this.device,
    this.previousMessages,
  }) : super(key: key);

  @override
  LoRaChatScreenState createState() => LoRaChatScreenState();
}

class LoRaChatScreenState extends State<LoRaChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Message> _messages = [];
  final MessageManager _messageManager = MessageManager();
  late Stream<List<Message>> _chatStream;

  @override
  void initState() {
    super.initState();

    _messages = MessageManager().getInitialMessages(widget.deviceName);

    _chatStream = MessageManager().getChatStream(widget.deviceName);
    _chatStream.listen((newMessages) {
      setState(() {
        _messages.addAll(newMessages.where((m) => !_messages.contains(m)));
      });
    });
  }

  @override
  void dispose() {
    _chatStream
        .drain(); // Remove this line if you are not using it to end the stream subscription
    _messageManager.closeChatStream(widget
        .deviceName); // Add a method to close the stream in your MessageManager
    super.dispose();
  }

  // void _setupBluetoothListener() async {
  //   const String serviceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  //   const String characteristicUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  //   await widget.device.requestMtu(512);

  //   final service = await widget.device.discoverServices().then((services) {
  //     return services.firstWhere((serv) => serv.uuid.toString() == serviceUUID);
  //   });

  //   final characteristic = service.characteristics.firstWhere(
  //     (char) => char.uuid.toString() == characteristicUUID,
  //   );

  //   await characteristic.setNotifyValue(true);

  //   // TODO: remove subscription of this when navigates away
  //   characteristic.lastValueStream.listen((value) {
  //     String text = utf8.decode(value);
  //     _receiveMessage(text);
  //   });
  // }

  // void _receiveMessage(String text) {
  //   if (text.isEmpty) return;

  //   Message message = Message(
  //     text: text,
  //     isSender: false,
  //   );
  //   setState(() {
  //     _messages.add(message);
  //     // TODO: Store the message
  //   });
  // }

  // void _sendMessage() async {
  //   final text = _controller.text.trim();

  //   Message myMessage = Message(
  //     text: text,
  //     isSender: true,
  //   );

  //   if (text.isNotEmpty) {
  //     setState(() {
  //       _messages.add(myMessage);
  //       _messageManager.storeMessage(myMessage, widget.deviceName);
  //     });
  //     _controller.clear();
  //   }

  //   const String serviceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  //   const String characteristicUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  //   await widget.device.requestMtu(512);

  //   final service = await widget.device.discoverServices().then((services) {
  //     return services.firstWhere((serv) => serv.uuid.toString() == serviceUUID);
  //   });

  //   final characteristic = service.characteristics.firstWhere(
  //     (char) => char.uuid.toString() == characteristicUUID,
  //   );

  //   var bytes = utf8.encode("${text}_${widget.deviceName}");

  //   final message = bytes;

  //   await characteristic.write(message, timeout: 30);
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deviceName.split("-")[0]),
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
                    onTap: () {
                      _messageManager.sendMessage(
                          _controller.text.trim(), widget.deviceName);
                      _controller.clear();
                    },
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
