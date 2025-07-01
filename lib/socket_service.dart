import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket _socket;

  void connect() {
    _socket = IO.io('ws://localhost:3000', <String, dynamic>{

      'transports': ['websocket'],
      'autoConnect': true,
      'reconnectionAttempts': 5,
      'reconnectionDelay': 1000,
    });

    _socket.connect();

    _socket.onConnect((_) {
      print('[SOCKET] Connected');
    });

    _socket.on('msg', (data) {
      print('[SOCKET] Message received: $data');
    });

    _socket.onDisconnect((_) {
      print('[SOCKET] Disconnected');
    });

    _socket.onConnectError((error) {
      print('[SOCKET] Connect error: $error');
    });

    _socket.onError((error) {
      print('[SOCKET] General error: $error');
    });
  }

  void sendMessage(String message) {


    if (_socket.connected) {
      _socket.emit('msg', message);

    } else {
      print('[SOCKET] Not connected. Message not sent.');
    }
  }

  void dispose() {
    _socket.dispose();
  }

  IO.Socket get socket => _socket;
}
