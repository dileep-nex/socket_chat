import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/chat_message_model.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  WebSocketChannel? channel;
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  bool _isConnected = false;
  String _username = '';
  String _connectionStatus = 'Disconnected';
  bool _hasShownDialog = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasShownDialog) {
      _hasShownDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showUsernameDialog();
      });
    }
  }

  void _showUsernameDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Your Username'),
          content: TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              hintText: 'Username',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                Navigator.of(context).pop();
                _username = value.trim();
                _connectToServer();
              }
            },
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (_usernameController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop();
                  _username = _usernameController.text.trim();
                  _connectToServer();
                }
              },
              child: Text('Connect'),
            ),
          ],
        );
      },
    );
  }

  void _connectToServer() {
    try {
      setState(() {
        _connectionStatus = 'Connecting...';
      });


      channel = WebSocketChannel.connect(
        Uri.parse('ws://localhost:3000'),
      );

      channel!.stream.listen(
            (message) {
          final data = jsonDecode(message);
          setState(() {
            _messages.add(ChatMessage.fromJson(data));
            _isConnected = true;
            _connectionStatus = 'Connected';
          });
          _scrollToBottom();
        },
        onError: (error) {
          setState(() {
            _isConnected = false;
            _connectionStatus = 'Connection Error';
          });
          _showSnackBar('Connection error: $error');
        },
        onDone: () {
          setState(() {
            _isConnected = false;
            _connectionStatus = 'Disconnected';
          });
          _showSnackBar('Connection closed');
        },
      );

      setState(() {
        _isConnected = true;
        _connectionStatus = 'Connected';
      });

    } catch (e) {
      setState(() {
        _isConnected = false;
        _connectionStatus = 'Failed to connect';
      });
      _showSnackBar('Failed to connect: $e');
    }
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty && _isConnected) {
      final message = {
        'type': 'message',
        'username': _username,
        'message': _controller.text,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      channel!.sink.add(jsonEncode(message));

      // Add own message to the list
      setState(() {
        _messages.add(ChatMessage.fromJson({
          ...message,
          'isOwn': true,
        }));
      });

      _controller.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _reconnect() {
    channel?.sink.close();
    _connectToServer();
  }

  @override
  void dispose() {
    channel?.sink.close();
    _controller.dispose();
    _usernameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Chat'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isConnected ? Icons.wifi : Icons.wifi_off),
            onPressed: _isConnected ? null : _reconnect,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                _connectionStatus,
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
              child: Text(
                'No messages yet.\nStart chatting!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              padding: EdgeInsets.all(8),
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Message input
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: _isConnected
                          ? 'Type a message...'
                          : 'Connect to start chatting',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    enabled: _isConnected,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _isConnected ? _sendMessage : null,
                  mini: true,
                  child: Icon(Icons.send),
                  backgroundColor: _isConnected ? Colors.blue : Colors.grey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isOwn = message.isOwn;
    final isSystem = message.type == 'system';

    if (isSystem) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.message,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
        isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isOwn) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[100],
              child: Text(
                message.username.isNotEmpty
                    ? message.username[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isOwn ? Colors.blue : Colors.grey[300],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isOwn && message.username.isNotEmpty)
                    Text(
                      message.username,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isOwn ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: isOwn ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isOwn) ...[
            SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green[100],
              child: Text(
                _username.isNotEmpty ? _username[0].toUpperCase() : 'M',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}