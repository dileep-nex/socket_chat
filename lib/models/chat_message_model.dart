
class ChatMessage {
  final String type;
  final String username;
  final String message;
  final int timestamp;
  final bool isOwn;

  ChatMessage({
    required this.type,
    required this.username,
    required this.message,
    required this.timestamp,
    this.isOwn = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      type: json['type'] ?? 'message',
      username: json['username'] ?? '',
      message: json['message'] ?? '',
      timestamp: json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      isOwn: json['isOwn'] ?? false,
    );
  }
}