import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:edconnect_mobile/utils/device_manager.dart';
import 'package:edconnect_mobile/widgets/glassmorphism.dart';
import 'package:provider/provider.dart';
import 'package:edconnect_mobile/constants.dart';
import 'package:edconnect_mobile/models/providers/themeprovider.dart';
import 'package:edconnect_mobile/models/user.dart';
import 'package:edconnect_mobile/signal_protocol/session_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatPage extends StatefulWidget {
  final AppUser recipient;
  final AppUser currentUser;
  final String orgName;
  final String userCollection;
  final String messageCollection;
  const ChatPage({
    super.key,
    required this.recipient,
    required this.currentUser,
    required this.orgName,
    required this.userCollection,
    required this.messageCollection,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();

  final storage = const FlutterSecureStorage();
  String? _warningMessage;

  late SharedPreferences _prefs;
  late SessionManager _sessionManager;
  bool _isSessionInitialized = false;
  List<Map<String, dynamic>> _messages = [];
  StreamSubscription<QuerySnapshot>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _sessionManager = SessionManager();

    // Initialize session
    _initializeSessionAndPreferences();
  }

  Future<void> _initializeSessionAndPreferences() async {
    await _initializeSession();
    await _initSharedPreferences();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    final String currentUserDeviceId =
        await DeviceManager().getUniqueDeviceId();
    _loadLocalMessages();
    _setupMessageListener(currentUserDeviceId);
    print('Chat page initialized');
  }

  void _loadLocalMessages() {
    String conversationId = '${widget.currentUser.id}-${widget.recipient.id}';

    Map<String, dynamic> conversations =
        jsonDecode(_prefs.getString('conversations') ?? '{}');
    print('conversations: $conversations');
    List<Map<String, dynamic>> messages = conversations[conversationId] != null
        ? List<Map<String, dynamic>>.from(
            conversations[conversationId]?['messages'])
        : [];
    print('messages: $messages');
    setState(() {
      _messages = messages;
      _messages.sort((a, b) => DateTime.parse(b['timestamp'])
          .compareTo(DateTime.parse(a['timestamp'])));
    });
  }

  void _setupMessageListener(String currentDeviceId) {
    _messageSubscription = FirebaseFirestore.instance
        .collection(widget.messageCollection)
        .where('recipient', isEqualTo: widget.currentUser.id)
        .where('sender', isEqualTo: widget.recipient.id)
        .where('recipientDeviceId', isEqualTo: currentDeviceId)
        .snapshots()
        .listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          await _handleNewMessage(change.doc);
        }
      }
    });
  }

  Future<void> _handleNewMessage(DocumentSnapshot doc) async {
    print('Handling new message: ${doc.data()}');
    final message = doc.data() as Map<String, dynamic>;
    if (!message.containsKey('message')) return;
    print('Message: ${message['message']}');
    print(_messages);
    final existingMessage = _messages.firstWhere(
      (msg) => msg['messageId'] == doc.id,
      orElse: () => <String, dynamic>{},
    );

    if (existingMessage.isNotEmpty) {
      // Message already exists, do not add it again
      await FirebaseFirestore.instance
          .collection(widget.messageCollection)
          .doc(doc.id)
          .delete();

      return;
    }

    final decryptedText =
        await _decryptMessage(message['message'], message['senderDeviceId']);
    final newMessage = {
      'senderId': message['sender'],
      'recipientId': message['recipient'],
      'message': decryptedText,
      'timestamp': DateTime.now().toIso8601String(),
      'messageId': doc.id,
    };

    setState(() {
      _messages.insert(0, newMessage);
    });
    await _storeMessageLocally(newMessage);
    print('Message added: $newMessage');
    print(widget.messageCollection);
    print(doc.id);
    try {
      await FirebaseFirestore.instance
          .collection(widget.messageCollection)
          .doc(doc.id)
          .delete();
    } catch (e) {
      print('Error deleting message: $e');
    }
    print('Message deleted');
  }

  Future<void> _initializeSession() async {
    for (var device in widget.recipient.deviceIds.entries) {
      try {
        // Check if an existing session exists for the recipient
        bool sessionExists = await _sessionManager.hasExistingSession(
            widget.recipient.id, device.key);
        if (sessionExists) {
          // Resume existing session
          await _sessionManager.resumeSession(widget.recipient.id, device.key);
        } else {
          final initialMessage = await _sessionManager.checkForInitialMessage(
              widget.currentUser.id,
              widget.recipient.id,
              widget.messageCollection);
          if (initialMessage != null) {
            await _sessionManager.processInitialMessage(
                widget.currentUser,
                widget.recipient,
                widget.orgName,
                initialMessage,
                widget.messageCollection);
          } else {
            // If no session with the users device exists, initiate a new session with the device
            final List<int> recipientPublicIdentityKey =
                List<int>.from(widget.recipient.publicIdentityKey!);
            final Map<String, dynamic> signedPreKeyDynamic =
                device.value['signed_pre_key'];
            final Map<String, List<int>> recipientSignedPublicPreKey =
                signedPreKeyDynamic.map(
              (key, value) => MapEntry(key, List<int>.from(value)),
            );
            final List<dynamic> oneTimePreKeysDynamic =
                device.value['one_time_pre_keys'];
            final List<Map<String, dynamic>> recipientOneTimePreKeys =
                oneTimePreKeysDynamic.cast<Map<String, dynamic>>();

            await _sessionManager.initiateSession(
              widget.currentUser,
              widget.recipient.id,
              recipientPublicIdentityKey,
              recipientSignedPublicPreKey,
              recipientOneTimePreKeys,
              device.key,
              widget.orgName,
              widget.userCollection,
              widget.messageCollection,
            );
          }
        }

        setState(() {
          _isSessionInitialized = true;
        });
      } catch (e) {
        setState(() {
          _warningMessage =
              'Failed to initialize session for device ${device.key}: $e';
        });
      }
    }
  }

  Future<void> _saveSessionState(String recipientId, String deviceId) async {
    final ratchet = _sessionManager.activeSessions[recipientId]![deviceId];

    if (ratchet == null) return;

    // Serialize session data
    final sessionData = jsonEncode({
      'rootKey': ratchet.rootKey,
      'sendingChainKey': ratchet.sendingChainKey,
      'receivingChainKey': ratchet.receivingChainKey,
      'skippedMessageKeys': ratchet.skippedMessageKeys,
    });

    // Store the session in secure storage
    await storage.write(key: 'session_$recipientId', value: sessionData);
  }

  Future<void> _sendMessage(
    String messageCollection,
  ) async {
    if (_messageController.text.isEmpty) return;
    final String currentDeviceId = await DeviceManager().getUniqueDeviceId();
    try {
      for (var device in widget.recipient.deviceIds.entries) {
        final ratchet =
            _sessionManager.activeSessions[widget.recipient.id]![device.key];
        if (ratchet == null) {
          setState(() {
            _warningMessage =
                'No active session found for recipient\'s device ${device.key}';
          });
          continue;
        }

        final plaintext =
            Uint8List.fromList(utf8.encode(_messageController.text));
        final encryptedMessage = await ratchet.encryptMessage(
            plaintext, await ratchet.ratchetSendingKey());

        await FirebaseFirestore.instance.collection(messageCollection).add({
          'sender': widget.currentUser.id,
          'recipient': widget.recipient.id,
          'message': base64Encode(encryptedMessage),
          'senderDeviceId': currentDeviceId,
          'recipientDeviceId': device.key,
          'timestamp': FieldValue.serverTimestamp(),
        });

        await _saveSessionState(widget.recipient.id, device.key);
      }
      final newMessage = {
        'senderId': widget.currentUser.id,
        'recipientId': widget.recipient.id,
        'message': _messageController.text,
        'senderDeviceId': currentDeviceId,
        'timestamp': DateTime.now().toIso8601String(),
      };

      setState(() {
        _messages.insert(0, newMessage);
      });

      await _storeMessageLocally(newMessage);
      _messageController.clear();
    } catch (e) {
      setState(() {
        _warningMessage = 'Failed to send message: $e';
      });
    }
  }

  Future<String> _decryptMessage(
      String encryptedMessage, String senderDeviceId) async {
    try {
      final ratchet =
          _sessionManager.activeSessions[widget.recipient.id]![senderDeviceId];
      if (ratchet == null) throw Exception('No active session found.');

      // Decode the encrypted message
      final encryptedBytes = base64Decode(encryptedMessage);
      // Decrypt the message using the receiving key
      final decryptedMessage = await ratchet.decryptMessage(
          encryptedBytes, await ratchet.ratchetReceivingKey());
      // Save the session state
      await _saveSessionState(widget.recipient.id, senderDeviceId);
      return utf8.decode(decryptedMessage);
    } catch (e) {
      return 'Error decrypting message: $e';
    }
  }

  Future<void> _storeMessageLocally(Map<String, dynamic> messageData) async {
    String conversationId = '${widget.currentUser.id}-${widget.recipient.id}';

    Map<String, dynamic> conversations =
        jsonDecode(_prefs.getString('conversations') ?? '{}');
    if (!conversations.containsKey(conversationId)) {
      conversations[conversationId] = {
        'senderId': messageData['senderId'],
        'recipientId': messageData['recipientId'],
        'messages': [],
      };
    }

    conversations[conversationId]['messages'].add(messageData);
    await _prefs.setString('conversations', jsonEncode(conversations));
  }

  void _clearChat() async {
    String conversationId = '${widget.currentUser.id}-${widget.recipient.id}';

    Map<String, dynamic> conversations =
        jsonDecode(_prefs.getString('conversations') ?? '{}');
    conversations.remove(conversationId);

    await _prefs.setString('conversations', jsonEncode(conversations));
    setState(() {
      _messages.clear();
    });
  }

  void _showClearChatConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Clear Chat'),
          content: Text(
              'Are you sure you want to clear the chat? This will only clear the chat on your device.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _clearChat();
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentColorSchemeProvider =
        Provider.of<ColorANDLogoProvider>(context);
    final databaseProvider = Provider.of<DatabaseCollectionProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(int.parse(currentColorSchemeProvider.primaryColor)),
                  Color(int.parse(currentColorSchemeProvider.secondaryColor)),
                ],
              ),
            ),
          ),

          // Main content with AppBar and chat
          Column(
            children: [
              // Regular AppBar with transparency
              AppBar(
                backgroundColor: themeProvider.darkTheme
                    ? Colors.grey.shade800.withOpacity(0.1)
                    : Colors.white.withOpacity(0.1), // Transparency
                elevation: 0, // No shadow
                title: Text(
                  '${widget.recipient.firstName} ${widget.recipient.lastName}',
                  style: const TextStyle(fontSize: 16),
                ),
                foregroundColor: Colors.white,
                leading: InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 3),
                      Icon(Icons.arrow_back_rounded, size: 24),
                      SizedBox(width: 1),
                      CircleAvatar(
                        radius: 18,
                        child: Text(widget.recipient.firstName[0]),
                      ),
                    ],
                  ),
                ),
                leadingWidth: 65,
                actions: [
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'clear_chat') {
                        _showClearChatConfirmationDialog(context);
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return [
                        PopupMenuItem<String>(
                          value: 'clear_chat',
                          child: Text('Clear Chat'),
                        ),
                      ];
                    },
                  ),
                ],
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Color(
                            int.parse(currentColorSchemeProvider.primaryColor)),
                        Color(int.parse(
                            currentColorSchemeProvider.secondaryColor)),
                      ],
                    ),
                  ),
                ),
              ),

              // Rest of the body
              Expanded(
                child: Column(
                  children: [
                    if (_warningMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8.0),
                        color: Colors.red,
                        child: Text(
                          _warningMessage!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    const SizedBox(height: 8),
                    // Chat messages
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width < 750
                              ? MediaQuery.of(context).size.width
                              : 750,
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            reverse:
                                true, // Keep reverse to ensure new messages appear at the bottom
                            itemCount: _messages.length +
                                1, // Add 1 for the encryption card
                            itemBuilder: (context, index) {
                              // Show the encryption card at the top
                              if (index == _messages.length) {
                                return Column(
                                  children: [
                                    GlassMorphismCard(
                                      start: 0.3,
                                      end: 0.3,
                                      color: Colors.yellow[500]!,
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.lock_outline,
                                              color: themeProvider.darkTheme
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                            Text(
                                              'End-to-end encrypted chat',
                                              softWrap: true,
                                              style: TextStyle(
                                                color: themeProvider.darkTheme
                                                    ? Colors.white
                                                    : Colors.black,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                );
                              }

                              // Show chat messages
                              final message = _messages[index];
                              final isCurrentUser =
                                  message['senderId'] == widget.currentUser.id;
                              return Column(
                                children: [
                                  Align(
                                    alignment: isCurrentUser
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor:
                                          0.66, // 2/3 of the screen width
                                      child: Card(
                                        // start: 0.3,
                                        // end: 0.3,
                                        // blurSigma: 3,
                                        color: isCurrentUser
                                            ? themeProvider.darkTheme
                                                ? Color(int.parse(
                                                    currentColorSchemeProvider
                                                        .primaryColor))
                                                : Color(int.parse(
                                                    currentColorSchemeProvider
                                                        .secondaryColor))
                                            : themeProvider.darkTheme
                                                ? Colors.grey.shade900
                                                : Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.only(
                                            bottomLeft: Radius.circular(15),
                                            bottomRight: Radius.circular(15),
                                            topLeft: isCurrentUser
                                                ? Radius.circular(15)
                                                : Radius.circular(0),
                                            topRight: isCurrentUser
                                                ? Radius.circular(0)
                                                : Radius.circular(15),
                                          ),
                                        ),
                                        // borderRadius: BorderRadius.only(
                                        //   bottomLeft: Radius.circular(15),
                                        //   bottomRight: Radius.circular(15),
                                        //   topLeft: isCurrentUser
                                        //       ? Radius.circular(15)
                                        //       : Radius.circular(0),
                                        //   topRight: isCurrentUser
                                        //       ? Radius.circular(0)
                                        //       : Radius.circular(15),
                                        // ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(5.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                message['message'],
                                                style: TextStyle(
                                                  color: themeProvider.darkTheme
                                                      ? Colors.white
                                                      : Colors.black,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Align(
                                                alignment:
                                                    Alignment.bottomRight,
                                                child: Text(
                                                  DateFormat.yMd(Localizations
                                                              .localeOf(context)
                                                          .toString())
                                                      .add_jm()
                                                      .format(DateTime.parse(
                                                              message[
                                                                  'timestamp'])
                                                          .toLocal()),
                                                  style: TextStyle(
                                                    color:
                                                        themeProvider.darkTheme
                                                            ? Colors.white54
                                                            : Colors.black54,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    // Input field
                    SizedBox(
                      width: MediaQuery.of(context).size.width < 750
                          ? MediaQuery.of(context).size.width
                          : 750,
                      child: Row(
                        children: [
                          Expanded(
                            child: GlassMorphismCard(
                              start: 0.9,
                              end: 0.9,
                              color: themeProvider.darkTheme
                                  ? Colors.grey.shade900
                                  : Colors.grey[100]!,
                              borderWidth: 1.5,
                              borderRadius: BorderRadius.circular(30),
                              child: TextField(
                                controller: _messageController,
                                maxLines: 6,
                                minLines: 1,
                                style: TextStyle(
                                  color: themeProvider.darkTheme
                                      ? Colors.white
                                      : Colors.black,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Secure Message',
                                  hintStyle: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    color: themeProvider.darkTheme
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 2.5, horizontal: 20.0),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.attach_file),
                                    color: themeProvider.darkTheme
                                        ? Colors.white
                                        : Colors.black,
                                    onPressed: () {},
                                  ),
                                ),
                              ),
                            ),
                          ),
                          FilledButton(
                            onPressed: _isSessionInitialized
                                ? () {
                                    _sendMessage(databaseProvider
                                        .customerSpecificCollectionMessaging);
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(12),
                              backgroundColor:
                                  _isSessionInitialized ? null : Colors.grey,
                            ),
                            child: const Icon(Icons.send),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
