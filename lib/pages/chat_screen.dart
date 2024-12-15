import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/gigachat_api.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final GigachatApi _gigachatApi = GigachatApi();
  final List<Map<String, String>> _messages = [];
  late Box _messagesBox;

  @override
  void initState() {
    super.initState();
    _initializeMessages();
  }

  Future<void> _initializeMessages() async {
    _messagesBox = Hive.box('chatHistory');
    final savedMessages =
        _messagesBox.values.cast<Map<String, String>>().toList();

    setState(() {
      _messages.addAll(savedMessages);
    });
  }

  Future<void> _saveMessage(Map<String, String> message) async {
    await _messagesBox.add(message);
  }

  Future<void> _handleSendMessage(String userMessage) async {
    final userMsg = {'role': 'user', 'content': userMessage};

    setState(() {
      _messages.add(userMsg);
    });

    await _saveMessage(userMsg);

    final reply = await _gigachatApi.sendMessage(userMessage);
    final botMsg = {
      'role': 'gigachat',
      'content': reply ?? 'Ошибка получения ответа.'
    };

    setState(() {
      _messages.add(botMsg);
    });
    await _saveMessage(botMsg);
  }

  Widget _buildMessageBubble(String content, bool isUserMessage) {
    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isUserMessage ? Colors.blue[400] : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isUserMessage ? const Radius.circular(12) : Radius.zero,
            bottomRight:
                isUserMessage ? Radius.zero : const Radius.circular(12),
          ),
        ),
        child: Text(
          content,
          style: TextStyle(
            color: isUserMessage ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text('Твой корманный чат-бот'),
            elevation: 4.0,
          ),
          body: Column(
            children: [
              _messages.isEmpty
                  ? const Expanded(
                      child: Center(
                        child: Text('Напишите свой вопрос чат-боту GigaChat!'),
                      ),
                    )
                  : Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isUserMessage = message['role'] == 'user';
                          return _buildMessageBubble(
                              message['content'] ?? '', isUserMessage);
                        },
                      ),
                    ),
              Padding(
                padding: const EdgeInsets.only(
                    top: 8.0, left: 8.0, right: 8.0, bottom: 24.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText: 'Введите сообщение...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.blue,
                      child: IconButton(
                        onPressed: () {
                          final message = _controller.text.trim();
                          if (message.isNotEmpty) {
                            _handleSendMessage(message);
                            _controller.clear();
                          }
                        },
                        icon: const Icon(Icons.send, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}
