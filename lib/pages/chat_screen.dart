import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:simple_todo/utils/theme.dart';
import '../utils/gigachat_api.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  const ChatScreen({super.key, required this.chatId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final GigachatApi _gigachatApi = GigachatApi();
  final List<Map<String, String>> _messages = [];
  late Box _messagesBox;
  late Box _chatsBox;
  String? _currentChatId;
  bool _isInitialized = false;
  File? _backgroundImage;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentChatId = widget.chatId;
    _initializeHive().then((_) {
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _isInitialized = true;
        });
      });
    });

    _loadBackgroundImageFromHive();
  }

  Future<void> _initializeHive() async {
    _messagesBox =  Hive.box('chatHistory');
    _chatsBox =  Hive.box('chatsList');
    await _initializeMessages();
  }

  Future<void> _initializeMessages() async {
    if (_currentChatId != null) {
      final savedMessages = _messagesBox.get(_currentChatId, defaultValue: []) as List;

      final typedMessages = savedMessages.map((message) {
        return Map<String, String>.from(message);
      }).toList();

      setState(() {
        _messages.clear();
        _messages.addAll(typedMessages);
      });
    }
  }

  Future<void> _saveMessage(Map<String, String> message) async {
    final savedMessages = _messagesBox.get(_currentChatId, defaultValue: []) as List;
    savedMessages.add(message);
    await _messagesBox.put(_currentChatId, savedMessages);
  }

  Future<void> _handleSendMessage(String userMessage) async {
    final userMsg = {'role': 'user', 'content': userMessage};

    setState(() {
      _messages.add(userMsg);
    });

    await _saveMessage(userMsg);
    final reply = await _gigachatApi.sendMessage(_messages);

    final botMsg = {
      'role': 'assistant',
      'content': reply ?? 'Ошибка получения ответа.'
    };

    setState(() {
      _messages.add(botMsg);
    });

    await _saveMessage(botMsg);

    _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut
    );
  }

  void _addNewChat() {
    final chatCount = _chatsBox.length;
    final newChatId = 'chat_${chatCount + 1}';
    _chatsBox.add(newChatId);
    setState(() {
      _currentChatId = newChatId;
    });
    _navigateToChat(newChatId);
    _initializeMessages();
  }

  void _navigateToChat(String chatId) async {
    setState(() {
      _currentChatId = chatId;
    });
    await _initializeMessages();
    await _loadBackgroundImageFromHive();
    setState(() {});
  }

  Future<void> _deleteChat(String chatId) async {
    int? keyToDelete;
    for (var key in _chatsBox.keys) {
      if (_chatsBox.get(key) == chatId) {
        keyToDelete = key;
        break;
      }
    }

    await _chatsBox.delete(keyToDelete);
    await _messagesBox.delete(chatId);

    final imageBox = await Hive.openBox('chatBackgroundImages');
    await imageBox.delete(chatId);

    if (_currentChatId == chatId) {
      if (_chatsBox.isNotEmpty) {
        _navigateToChat(_chatsBox.values.first);
      } else {
        setState(() {
          _currentChatId = null;
          _messages.clear();
        });
      }
    }

    setState(() {});
  }

  Future<void> _pickBackgroundImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      final imageFile = File(pickedImage.path);
      setState(() {
        _backgroundImage = File(pickedImage.path);
      });
      await _saveBackgroundImageToHive(imageFile);
    }
  }

  Future<void> _loadBackgroundImageFromHive() async {
    final imageBox = await Hive.openBox('chatBackgroundImages');
    final Uint8List? imageBytes = imageBox.get(_currentChatId);

    if (imageBytes != null) {
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/background_${_currentChatId}.jpg';
      final imageFile = File(tempPath);
      await imageFile.writeAsBytes(imageBytes);
      setState(() {
        _backgroundImage = imageFile;
      });
    } else {
      setState(() {
        _backgroundImage = null;
      });
    }
  }


  Future<void> _saveBackgroundImageToHive(File imageFile) async {
    final imageBox = await Hive.openBox('chatBackgroundImages');

    final Uint8List imageBytes = await imageFile.readAsBytes();

    await imageBox.put(widget.chatId, imageBytes);

    setState(() {
      _backgroundImage = imageFile;
    });
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
            bottomRight: isUserMessage ? Radius.zero : const Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUserMessage)
              Padding(
                padding: const EdgeInsets.only(bottom: 5, top: 5),
                child: InkWell(
                  child: const Icon(Icons.copy, color: Colors.black54, size: 16),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Текст скопирован в буфер обмена'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            Text(
              content,
              style: TextStyle(
                color: isUserMessage ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentChatId!),
          elevation: 4.0,
          leading: Builder(
            builder: (context) {
              return IconButton(
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                icon: const Icon(Icons.menu)
              );
            },
          ),
          actions: [
            IconButton(
              onPressed: () {
                _addNewChat();
              },
              icon: const Icon(Icons.add),
            ),
            IconButton(
              onPressed: _pickBackgroundImage,
              icon: const Icon(Icons.image),
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Список чатов', style: TextStyle(fontSize: 22),),
                    Switch(
                      value: themeProvider.themeMode == ThemeMode.dark,
                      onChanged: (bool value) {
                        themeProvider.toggleTheme();
                      }
                    )
                  ],
                ),
              ),
              ..._chatsBox.values.map((chatId) {
                return ListTile(
                  title: Text('$chatId'),
                  onTap: () {
                    _navigateToChat(chatId);
                    Navigator.pop(context);
                  },
                  trailing: InkWell(
                    onTap: () {
                      _deleteChat(chatId);
                    },
                    child: const Icon(Icons.delete, color: Colors.red,),
                  ),
                );
              }),
            ],
          ),
        ),
        body: Container(
          decoration: _backgroundImage != null
              ? BoxDecoration(
            image: DecorationImage(
              image: FileImage(_backgroundImage!),
              fit: BoxFit.cover,
            ),
          )
              : null,
          child: Column(
            children: [
              _messages.isEmpty
                  ? Expanded(
                      child: Center(
                        child: Text(
                          'Напишите свой вопрос чат-боту GigaChat!',
                          style: _backgroundImage != null ? TextStyle(color: Colors.white, fontSize: 22) : TextStyle(color: Colors.black, fontSize: 22),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
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
              Container(
                color: Theme.of(context).primaryColor,
                padding: const EdgeInsets.only(
                    top: 8.0, left: 8.0, right: 8.0, bottom: 36.0),
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
                      backgroundColor: Colors.blueAccent,
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
        ),
      )
    );
  }
}
