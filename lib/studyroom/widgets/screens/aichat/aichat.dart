import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flourish_web/studyroom/widgets/screens/aichat/aimessage.dart';
import 'package:universal_html/html.dart' as html;
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flourish_web/api/auth_service.dart';
import 'package:flourish_web/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:uuid/uuid.dart';

class UserMessage {
  String message;
  Uint8List? imageFile;

  UserMessage(this.message, this.imageFile);
}

class AiChat extends StatefulWidget {
  const AiChat({super.key});

  @override
  State<AiChat> createState() => _AiChatState();
}

class _AiChatState extends State<AiChat> {
  final FocusNode _keyboardListenerFocusNode = FocusNode();
  final FocusNode _textInputFocusNode = FocusNode();

  final TextEditingController _textEditingController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final OpenAI openAi = OpenAI.instance.build(
      token: dotenv.env['OPENAI_PROJECT_API_KEY'],
      baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 120)),
      enableLog: true);

  bool _isPasting = false;
  bool _showScrollToBottomButton = false;
  bool _loadingResponse = false;

  String? _profilePictureUrl;

  final List<UserMessage> _userMessages = [];
  final List<String> _aiMessages = [];

  Uint8List? _imageFile;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _getProfileUrl();
    _scrollController.addListener(_scrollListener);
  }

  void _getProfileUrl() async {
    await AuthService().getProfilePictureUrl().then((value) {
      setState(() {
        _profilePictureUrl = value;
      });
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent) {
      setState(() {
        _showScrollToBottomButton = true;
      });
    } else {
      setState(() {
        _showScrollToBottomButton = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _textEditingController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastLinearToSlowEaseIn,
      );
    }
  }

  void _sendMessage() {
    if (_imageFile == null) {
      _sendTextOnly();
    } else {
      _sendImage();
    }
  }

  void _sendTextOnly() async {
    if (_textEditingController.text.isNotEmpty && !_loadingResponse) {
      final userMessage = _textEditingController.text;

      setState(() {
        _loadingResponse = true;
        _userMessages.add(UserMessage(userMessage, null));
      });

      // Clear the text field and ensure it's focused again
      _textEditingController.clear();
      FocusScope.of(context).requestFocus(_textInputFocusNode);
      _scrollToBottom();

      final request = ChatCompleteText(messages: [
        Map.of({'role': 'user', 'content': userMessage})
      ], maxToken: 1000, model: Gpt4OMiniChatModel());

      setState(() {
        _aiMessages.add('');
      });

      final response = await openAi.onChatCompletion(request: request);

      for (var element in response!.choices) {
        setState(() {
          _aiMessages.last = (element.message!.content);
          _loadingResponse = false;
        });
      }
    }
  }

  void _sendImage() async {
    if (_loadingResponse || _imageUrl == null) return;

    late final String userMessage;
    if (_textEditingController.text.isEmpty) {
      userMessage = '';
    } else {
      userMessage = _textEditingController.text;
    }

    _textEditingController.clear();

    setState(() {
      _loadingResponse = true;
      _userMessages.add(UserMessage(userMessage, _imageFile));
      _aiMessages.add('');
      _imageFile = null;
    });

    final request = ChatCompleteText(
      messages: [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': userMessage},
            {
              'type': 'image_url',
              'image_url': {'url': _imageUrl}
            }
          ]
        }
      ],
      maxToken: 1000,
      model: Gpt4OMiniChatModel(),
    );

    final response = await openAi.onChatCompletion(request: request);

    setState(() {
      _imageUrl = null;
      String? responseText = response?.choices[0].message!.content;
      _aiMessages.last = responseText!;
      _loadingResponse = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const BorderRadius borderRadius =
        BorderRadius.only(topLeft: Radius.circular(40.0));
    return SizedBox(
      width: 400,
      child: KeyboardListener(
        focusNode: _keyboardListenerFocusNode,
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.enter) {
            _sendMessage();
          }

          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.control ||
                  event.logicalKey == LogicalKeyboardKey.meta)) {
            setState(() {
              _isPasting = true;
            });
          }

          if (event is KeyUpEvent &&
              (event.logicalKey == LogicalKeyboardKey.control ||
                  event.logicalKey == LogicalKeyboardKey.meta)) {
            setState(() {
              _isPasting = false;
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.only(left: 10),
          height: MediaQuery.of(context).size.height - 80,
          child: ClipRRect(
            borderRadius: borderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(220, 220, 220, 1),
                  borderRadius: borderRadius,
                ),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount:
                                _userMessages.length + _aiMessages.length,
                            itemBuilder: (context, index) {
                              final isUser = index % 2 == 0;
                              final message = isUser
                                  ? _userMessages[index ~/ 2].message
                                  : _aiMessages[index ~/ 2];

                              final imageFile = isUser
                                  ? _userMessages[index ~/ 2].imageFile
                                  : null;

                              return AiMessage(
                                isUser: isUser,
                                message: message,
                                profilePictureUrl: _profilePictureUrl,
                                imageFile: imageFile,
                                onCopyIconPressed: (value) =>
                                    _copyToClipboard(value),
                                isLoadingResponse: _loadingResponse &&
                                    index + 1 ==
                                        _aiMessages.length +
                                            _userMessages
                                                .length, //only set loading to true if it is the last message
                              );
                            },
                          ),
                        ),
                        buildTextInputFields(),
                      ],
                    ),
                    Visibility(
                      visible: _showScrollToBottomButton,
                      child: Positioned(
                        bottom: 80,
                        right: 20,
                        child: FloatingActionButton(
                          mini: true,
                          onPressed: _scrollToBottom,
                          child: const Icon(Icons.arrow_downward),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextInputFields() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(10.0),
            ),
            color: Color.fromRGBO(170, 170, 170, 1),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 10.0,
            horizontal: 30.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_imageFile != null)
                ImagePreview(
                    imageFile: _imageFile,
                    onDelete: () {
                      setState(() {
                        _imageFile = null;
                      });
                    }),
              Row(
                children: [
                  Expanded(
                      child: TextField(
                    controller: _textEditingController,
                    focusNode: _textInputFocusNode,
                    cursorColor: kFlourishBlackish,
                    maxLines:
                        7, // Set this to null to let the TextField grow vertically
                    minLines: 1, // Start with a single line
                    textInputAction: TextInputAction
                        .newline, // Set action to newline (multiline input)
                    decoration: InputDecoration(
                      focusColor: kFlourishBlackish,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color:
                              kFlourishBlackish, // Set the border color when focused
                        ),
                      ),
                      hoverColor: kFlourishBlackish,
                      hintText: 'Type a message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    inputFormatters: [
                      if (_isPasting)
                        NoEnterInputFormatter() // keep a new line from forming in the next message when enter is sent
                      // Add more formatters if needed
                    ],
                    onChanged: (text) {
                      if (text.contains('\n')) {
                        // Remove the newline character
                        _textEditingController.text = text.replaceAll('\n', '');
                        // Place the cursor at the end of the text
                        _textEditingController.selection =
                            TextSelection.fromPosition(TextPosition(
                                offset: _textEditingController.text.length));
                      }
                    },
                  )),
                  IconButton(
                    icon: const Icon(Icons.image_outlined),
                    onPressed: _pickImage,
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_upward_sharp),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickImage() async {
    final file = await ImagePickerWeb.getImageAsFile();

    // load the file for optimistic UI updates
    final reader = html.FileReader();
    reader.onLoadEnd.listen((event) {
      setState(() {
        _imageFile = reader.result as Uint8List;
      });
    });

    reader.readAsArrayBuffer(file!);

    final filename = const Uuid().v4();
    final ref = FirebaseStorage.instance.ref().child('openai/$filename');
    await ref.putBlob(file);

    _imageUrl = await ref.getDownloadURL();
  }

  void _disposeImage() async {
    if (_imageUrl == null) return;
    final ref = FirebaseStorage.instance.refFromURL(_imageUrl!);
    await ref.delete();
  }
}

class ImagePreview extends StatefulWidget {
  const ImagePreview({
    super.key,
    required Uint8List? imageFile,
    required this.onDelete,
  }) : _imageFile = imageFile;

  final Uint8List? _imageFile;
  final VoidCallback onDelete;

  @override
  State<ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<ImagePreview> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) {
        setState(() {
          _isHovering = true;
        });
      },
      onExit: (event) {
        setState(() {
          _isHovering = false;
        });
      },
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 140,
                width: 140,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                    image: DecorationImage(
                  fit: BoxFit.cover,
                  image: MemoryImage(widget._imageFile!),
                )),
              ),
              if (_isHovering)
                Positioned(
                  right: 0,
                  child: IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline_outlined,
                      color: Colors.white,
                    ),
                    onPressed: widget.onDelete,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10.0),
        ],
      ),
    );
  }
}

class NoEnterInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Check if the new text contains newline characters
    if (newValue.text.contains('\n')) {
      // Return old value to ignore the newline input
      return oldValue;
    }
    // Otherwise, accept the new value
    return newValue;
  }
}