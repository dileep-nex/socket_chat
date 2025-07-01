import 'dart:io';
import 'dart:convert';

List<WebSocket> clients = [];

void main() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 3000);
  print('Chat server running at ws://${server.address.address}:${server.port}');

  await for (HttpRequest request in server) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      WebSocket socket = await WebSocketTransformer.upgrade(request);
      clients.add(socket);

      print('Client connected. Total clients: ${clients.length}');

      socket.listen(
            (message) {
          print('Received: $message');
          final messageData = jsonDecode(message);
          broadcastMessage(messageData, socket);
        },
        onDone: () {
          clients.remove(socket);
          print('Client disconnected. Total clients: ${clients.length}');
        },
        onError: (error) {
          print('WebSocket error: $error');
          clients.remove(socket);
        },
      );

      // Send welcome message
      socket.add(jsonEncode({
        'type': 'system',
        'message': 'Welcome to the chat!',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }));
    }
  }
}

void broadcastMessage(Map<String, dynamic> messageData, WebSocket sender) {
  final message = jsonEncode(messageData);

  // Send to all clients except the sender
  for (WebSocket client in List.from(clients)) {
    if (client != sender && client.readyState == WebSocket.open) {
      try {
        client.add(message);
      } catch (e) {
        print(' Error sending to client: $e');
        clients.remove(client);
      }
    }
  }
}