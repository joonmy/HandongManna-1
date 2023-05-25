/*
* Chatting Page
* Front_Owner: KimYounghun
*/
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter/material.dart';
import 'package:bubble/bubble.dart';
import 'package:handong_manna/constants/constants.dart';
import 'package:handong_manna/constants/kor_constants.dart';
import 'package:handong_manna/models/message_chat.dart';
import 'package:handong_manna/models/models.dart';
import 'package:handong_manna/pages/chat_profile_page.dart';
import 'package:handong_manna/providers/chat_providers.dart';
import 'package:provider/provider.dart';

String randomString() {
  final random = Random.secure();
  final values = List<int>.generate(16, (i) => random.nextInt(255));
  return base64UrlEncode(values);
}

String randomName() {
  final id1 = new Random().nextInt(listDongsa.length);
  final id2 = new Random().nextInt(listMyeongsa.length);
  return listDongsa[id1] + listMyeongsa[id2];
}

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<types.Message> _messages = [];
  final _user = const types.User(id: 'sylmC1z7m2CG33Cu2aF7');
  int _messageCount = 0;

  String groupChatId = "QKGhVnLjWeeZPglGcdNc-sylmC1z7m2CG33Cu2aF7";
  int _limit = 20;

  String username = randomName();
  ChatProvider? chatProvider;

  @override
  void initState() {
    super.initState();
    chatProvider = Provider.of<ChatProvider>(context, listen: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    chatProvider!.getMessageCount(groupChatId).then((count) {
      setState(() {
        _messageCount = count;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.mainBlue,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0.0,
        backgroundColor: ColorPalette.mainBlue,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: ColorPalette.mainWhite,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if(_messageCount > 200){
                          Navigator.pushNamed(context, '/chat_profile',
                              arguments: ChatProfilePageArguments(
                                  isNameOpen: true,
                                  isIntroduceOpen: true,
                                  isProfileOpen: true,
                                  isOccupationOpen: true));
                        }else if(_messageCount > 150){
                          Navigator.pushNamed(context, '/chat_profile',
                              arguments: ChatProfilePageArguments(
                                  isNameOpen: true,
                                  isIntroduceOpen: true,
                                  isProfileOpen: false,
                                  isOccupationOpen: true));
                        }else if(_messageCount > 100){
                          Navigator.pushNamed(context, '/chat_profile',
                              arguments: ChatProfilePageArguments(
                                  isNameOpen: false,
                                  isIntroduceOpen: true,
                                  isProfileOpen: false,
                                  isOccupationOpen: true));
                        }else if(_messageCount > 50){
                          Navigator.pushNamed(context, '/chat_profile',
                              arguments: ChatProfilePageArguments(
                                  isNameOpen: false,
                                  isIntroduceOpen: true,
                                  isProfileOpen: false,
                                  isOccupationOpen: false));
                        }else{
                          Navigator.pushNamed(context, '/chat_profile',
                              arguments: ChatProfilePageArguments(
                                  isNameOpen: false,
                                  isIntroduceOpen: false,
                                  isProfileOpen: false,
                                  isOccupationOpen: false));
                        }
                      },
                      child: CircleAvatar(
                          radius: MediaQuery.of(context).size.width * 0.06,
                          //TODOLIST: load image from Database
                          backgroundImage: null,
                          child: Stack(children: [
                            Align(
                                alignment: Alignment.bottomRight,
                                child: CircleAvatar(
                                    radius: MediaQuery.of(context).size.width *
                                        0.025,
                                    backgroundColor: Colors.white,
                                    //TODOLIST: online -> green offline -> green
                                    child: CircleAvatar(
                                        radius:
                                            MediaQuery.of(context).size.width *
                                                0.020,
                                        backgroundColor: Colors.green)))
                          ])),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                    Text("$username\nOnline")
                  ],
                ),
              ],
            ),
            // Expanded(
            //   child: Center(child: Text('Test')),
            // ),
          ],
        ),
        actions: [
          Padding(
              padding: EdgeInsets.fromLTRB(
                  0, 0, MediaQuery.of(context).size.width * 0.08, 0),
              child: Row(
                children: [
                  Text("$_messageCount"),
                  // TODO: Change to the number of existing messages
                  SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                  Icon(
                    Icons.chat,
                    color: ColorPalette.mainWhite,
                  ),
                ],
              )),
        ],
      ),
      body: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
        // Replace 'groupChatId' with the appropriate variable
        child: StreamBuilder<QuerySnapshot>(
          // stream: _messagesRef.orderBy(FirestoreConstants.timestamp, descending: true).snapshots(),
          stream: getChatStream(context, groupChatId, 50),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            chatProvider!.getMessageCount(groupChatId).then((count) {
              setState(() {
                _messageCount = count;
              });
            });

            // Todo: fill _messages
            _messages.clear();
            _messages.addAll(
              snapshot.data!.docs.map((doc) {
                final message = MessageChat.fromDocument(doc);
                return message.toChatTypeMessage(_user);
              }).toList(),
            );

            return Chat(
              bubbleBuilder: _bubbleBuilder,
              theme: const DefaultChatTheme(
                  inputBackgroundColor: ColorPalette.weakWhite,
                  inputTextColor: ColorPalette.strongGray,
                  sendButtonIcon: Icon(
                    Icons.send,
                    color: ColorPalette.mainBlue,
                  ),
                  backgroundColor: ColorPalette.mainWhite,
                  primaryColor: ColorPalette.mainBlue),
              messages: _messages,
              onSendPressed: _handleSendPressed,
              user: _user,
            );
          },
        ),
      ),
    );
  }

  Widget _bubbleBuilder(
    Widget child, {
    required message,
    required nextMessageInGroup,
  }) =>
      Bubble(
        child: child,
        padding: const BubbleEdges.fromLTRB(2, 0, 2, 0),
        color: _user.id != message.author.id ||
                message.type == types.MessageType.image
            ? ColorPalette.weakWhite
            : ColorPalette.mainBlue,
        margin: nextMessageInGroup
            ? const BubbleEdges.symmetric(horizontal: 6)
            : null,
        nipWidth: 2,
        nipHeight: 15,
        nip: nextMessageInGroup
            ? BubbleNip.no
            : _user.id != message.author.id
                ? BubbleNip.leftBottom
                : BubbleNip.rightBottom,
        borderWidth: MediaQuery.of(context).size.width * 0.02,
        radius: const Radius.circular(20.0),
      );

  Stream<QuerySnapshot> getChatStream(
      BuildContext context, String groupChatId, int limit) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    return chatProvider.getChatStream(groupChatId, limit);
  }

  void _handleSendPressed(types.PartialText message) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.sendMessage(
      message.text,
      1,
      groupChatId, // TODO: Replace 'groupChatId' with the appropriate variable
      "sylmC1z7m2CG33Cu2aF7",
      // TODO: Replace 'this HARDCODING' with the appropriate variable
      "QKGhVnLjWeeZPglGcdNc",
    );

    chatProvider.getMessageCount(groupChatId).then((count) {
      chatProvider.setMessageCount(groupChatId, count + 1);
    });
  }
}
