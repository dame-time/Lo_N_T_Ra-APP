import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lo_n_t_ra/model/message.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MessageManager {
  static final MessageManager _instance = MessageManager._internal();

  static BluetoothDevice? _device;

  static const String serviceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String characteristicUUID =
      "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  static int sentMessages = 0;

  Map<String, StreamController<List<Message>>> _chatStreamControllers = {};
  Map<String, List<Message>> _chatMessages = {};
  List<String> _messageACKs = [];
  Set<String> _receivedMessageIds = Set();

  Timer? _ackTimer;

  factory MessageManager() {
    return _instance;
  }

  MessageManager._internal();

  void _setupBluetoothListener(BluetoothDevice device) async {
    await device.requestMtu(512);

    final service = await device.discoverServices().then((services) {
      return services.firstWhere((serv) => serv.uuid.toString() == serviceUUID);
    });

    final characteristic = service.characteristics.firstWhere(
      (char) => char.uuid.toString() == characteristicUUID,
    );

    await characteristic.setNotifyValue(true);

    _device = device;

    // TODO: remove subscription of this when navigates away
    characteristic.lastValueStream.listen((value) {
      String text = utf8.decode(value);
      print("RECEIVED: " +
          text +
          "- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
      var payload = text.split("~");

      if (payload.length < 4) return;

      _messageACKs.add("MACK:${payload[3]}");
      _receiveMessage(payload[1], payload[0], payload[3],
          int.parse(payload[2]) + sentMessages);

      // Cancel the existing timer, if any
      _ackTimer?.cancel();

      // Create a new timer that will trigger after 1 second
      _ackTimer = Timer(const Duration(seconds: 1), () {
        _sendAllACKs();
      });
    });
  }

  void _sendAllACKs() async {
    for (var messageACK in _messageACKs) {
      await _sendKeywordMessage(
          messageACK); // Wait for each ACK to be sent before proceeding
    }
    _messageACKs.clear();
    print("ACK list cleared.");
  }

  // Call this method when a device is connected
  void startListeningForDevice(BluetoothDevice device) {
    // _loadPreviousMessages(device.localName);
    _loadAllPreviousMessages();
    _setupBluetoothListener(device);
  }

  // Call this method when a device is disconnected
  void stopListeningForDevice(BluetoothDevice device) {
    _chatStreamControllers[device.localName]?.close();
    _chatStreamControllers.remove(device.localName);
    // Optionally, clear messages in SharedPreferences
  }

  Future<void> clearMessages(String deviceName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove("${deviceName}_messages");
    _chatMessages.remove(deviceName);
    _chatStreamControllers[deviceName]?.add([]);
    prefs.clear();
  }

  Future<void> _loadPreviousMessages(String deviceName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final messageJsonList = prefs.getStringList("${deviceName}_messages") ?? [];
    final messages = messageJsonList
        .map((json) => Message.fromJson(jsonDecode(json)))
        .toList();
    _chatMessages[deviceName] = messages;
  }

  Future<void> _loadAllPreviousMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.getKeys().forEach((key) {
      if (key.endsWith("_messages")) {
        final messageJsonList = prefs.getStringList(key) ?? [];
        final messages = messageJsonList
            .map((json) => Message.fromJson(jsonDecode(json)))
            .toList();
        String deviceName = key.replaceAll("_messages", "");
        _chatMessages[deviceName] = messages;
      }
    });
  }

  void _receiveMessage(
      String text, String deviceName, String messageId, int order) {
    if (_receivedMessageIds.contains(messageId)) {
      print("Duplicate message $messageId discarded.");
      return;
    }

    _receivedMessageIds.add(messageId);

    Message message = Message(
      text: text,
      isSender: false,
      order: order, // include the order in the message
    );

    if (_chatMessages.containsKey(deviceName)) {
      _chatMessages[deviceName]!.add(message);
      _chatMessages[deviceName]!
          .sort((a, b) => a.order.compareTo(b.order)); // Sort by order
    } else {
      _chatMessages[deviceName] = [message];
    }

    _storeMessages(deviceName, _chatMessages[deviceName]!);
    _chatStreamControllers[deviceName]?.add(_chatMessages[deviceName]!);
  }

  Future<void> _storeMessages(String deviceName, List<Message> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final messageJsonList =
        messages.map((msg) => jsonEncode(msg.toJson())).toList();
    prefs.setStringList("${deviceName}_messages", messageJsonList);
  }

  void storeMessage(Message message, String deviceName) {
    if (_chatMessages.containsKey(deviceName)) {
      _chatMessages[deviceName]!.add(message);
    } else {
      _chatMessages[deviceName] = [message];
    }

    _storeMessages(deviceName, _chatMessages[deviceName]!);
    _chatStreamControllers[deviceName]?.add(_chatMessages[deviceName]!);
  }

  void sendMessage(String text, String destinationDevice) async {
    Message myMessage = Message(
      text: text,
      isSender: true,
      order: _receivedMessageIds.length + sentMessages,
    );

    sentMessages++;

    if (text.isNotEmpty) storeMessage(myMessage, destinationDevice);

    await _device!.requestMtu(512);

    final service = await _device!.discoverServices().then((services) {
      return services.firstWhere((serv) => serv.uuid.toString() == serviceUUID);
    });

    final characteristic = service.characteristics.firstWhere(
      (char) => char.uuid.toString() == characteristicUUID,
    );

    var bytes = utf8.encode("${text}_$destinationDevice");

    final message = bytes;

    await characteristic.write(message, timeout: 30);
  }

  Future<void> _sendKeywordMessage(String text) async {
    await _device!.requestMtu(32);

    final service = await _device!.discoverServices().then((services) {
      return services.firstWhere((serv) => serv.uuid.toString() == serviceUUID);
    });

    final characteristic = service.characteristics.firstWhere(
      (char) => char.uuid.toString() == characteristicUUID,
    );

    var bytes = utf8.encode(text);
    final message = bytes;

    await characteristic.write(message, timeout: 30);
  }

  Stream<List<Message>> getChatStream(String deviceName) {
    if (_chatStreamControllers.containsKey(deviceName)) {
      return _chatStreamControllers[deviceName]!.stream.asBroadcastStream();
    } else {
      _chatStreamControllers[deviceName] =
          StreamController<List<Message>>.broadcast();
      return _chatStreamControllers[deviceName]!.stream;
    }
  }

  void closeChatStream(String deviceName) {
    _chatStreamControllers[deviceName]?.close();
    _chatStreamControllers.remove(deviceName);
  }

  List<Message> getInitialMessages(String deviceName) {
    return _chatMessages[deviceName] ?? [];
  }
}
