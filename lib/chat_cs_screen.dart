import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:zelvira/components/custom_network_image.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';

class ChatMessage {
  final String senderId;
  final String senderRole;
  final String content;
  final String? attachmentUrl;
  final String type;

  ChatMessage({
    required this.senderId,
    required this.senderRole,
    required this.content,
    this.attachmentUrl,
    required this.type,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      senderId: json['senderId'] ?? '',
      senderRole: json['senderRole'] ?? '',
      content: json['content'] ?? '',
      attachmentUrl: json['attachmentUrl'],
      type: json['type'] ?? 'CHAT',
    );
  }
}

class ChatCsScreen extends StatefulWidget {
  final String roomId;
  const ChatCsScreen({super.key, this.roomId = 'general'});

  @override
  _ChatCsScreenState createState() => _ChatCsScreenState();
}

class _ChatCsScreenState extends State<ChatCsScreen> {
  StompClient? stompClient;
  List<ChatMessage> messages = [];
  final TextEditingController _textController = TextEditingController();
  bool isConnected = false;
  PlatformFile? _selectedFile;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
    _connectWebSocket();
  }

  void _fetchHistory() async {
    try {
      var response = await Dio().get(
        'http://10.0.2.2:8080/api/v1/chat/${widget.roomId}/history',
      );
      if (response.data['success'] == true) {
        if (!mounted) return;
        List<dynamic> data = response.data['data'];
        setState(() {
          messages = data.map((json) => ChatMessage.fromJson(json)).toList();
        });
      }
      // ignore: empty_catches
    } catch (e) {}
  }

  void _connectWebSocket() {
    stompClient = StompClient(
      config: StompConfig(
        url: 'ws://10.0.2.2:8080/ws-chat-native',
        onConnect: onConnectCallback,
        onWebSocketError: (dynamic error) => print(error.toString()),
      ),
    );
    stompClient!.activate();
  }

  void onConnectCallback(StompFrame frame) {
    setState(() {
      isConnected = true;
    });

    stompClient!.subscribe(
      destination: '/topic/room/${widget.roomId}',
      callback: (StompFrame frame) {
        if (frame.body != null) {
          Map<String, dynamic> result = json.decode(frame.body!);
          setState(() {
            messages.add(ChatMessage.fromJson(result));
          });
        }
      },
    );

    stompClient!.send(
      destination: '/app/chat/${widget.roomId}/addUser',
      body: json.encode({
        'roomId': widget.roomId,
        'senderId': 'CS_User',
        'senderRole': 'CS',
        'type': 'JOIN',
      }),
    );
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      if (!mounted) return;
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  Future<String?> _uploadFile() async {
    if (_selectedFile == null) return null;

    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          _selectedFile!.path!,
          filename: _selectedFile!.name,
        ),
      });

      var response = await Dio().post(
        'http://10.0.2.2:8080/api/v1/upload',
        data: formData,
      );
      return response.data['url'];
    } catch (e) {
      return null;
    }
  }

  void _sendMessage() async {
    if (_textController.text.trim().isEmpty && _selectedFile == null) return;
    if (stompClient == null || !isConnected) return;

    String? attachmentUrl;
    if (_selectedFile != null) {
      attachmentUrl = await _uploadFile();
      if (!mounted) return;
      setState(() {
        _selectedFile = null;
      });
    }

    stompClient!.send(
      destination: '/app/chat/${widget.roomId}/sendMessage',
      body: json.encode({
        'roomId': widget.roomId,
        'senderId': 'CS_User',
        'senderRole': 'CS',
        'content': _textController.text,
        'attachmentUrl': attachmentUrl,
        'type': 'CHAT',
      }),
    );
    _textController.clear();
  }

  @override
  void dispose() {
    stompClient?.deactivate();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat CS - Room: ${widget.roomId}'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          if (!isConnected)
            Container(
              color: Colors.yellow,
              width: double.infinity,
              padding: EdgeInsets.all(8),
              child: Text(
                'Connecting to chat server...',
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                var msg = messages[index];
                bool isMe = msg.senderRole == 'CS';

                if (msg.type == 'JOIN') {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        '${msg.senderId} joined',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  );
                }

                return Align(
                  alignment: isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.senderId,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 4),
                        if (msg.content.isNotEmpty) Text(msg.content),
                        if (msg.attachmentUrl != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: CustomNetworkImage(
                              msg.attachmentUrl!,
                              width: 150,
                              errorBuilder: (context, error, stackTrace) {
                                return Text(
                                  'Attachment: File sent',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_selectedFile != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Icon(Icons.attach_file, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedFile!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () => setState(() => _selectedFile = null),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(icon: Icon(Icons.attach_file), onPressed: _pickFile),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
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
