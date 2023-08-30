class Message {
  final String text;
  final bool isSender;
  final int order;

  Message({required this.text, required this.isSender, required this.order});

  // Convert Message instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isSender': isSender,
      'order': order,
    };
  }

  // Create Message instance from JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      text: json['text'] as String,
      isSender: json['isSender'] as bool,
      order: json['order'] as int,
    );
  }
}
