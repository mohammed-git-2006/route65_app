import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:route65/auth_engine.dart';
import 'package:route65/chatgpt_api.dart';

import 'l10n/l10n.dart';


class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});


  static void endSession(UserProfile userProfile) {
    FirebaseFirestore.instance.collection('app-users').doc(userProfile.uid).set({'openai_thread_id' : null}, SetOptions(merge: true));
  }

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  OpenAIAPI openai = OpenAIAPI();
  final scrollController = ScrollController();
  final inputController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dic = L10n.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(dic.chatbot_title),
      ),

      drawerEnableOpenDragGesture: true,
      primary: true,

      body: loading ? Center(child: Lottie.asset('assets/loading.json'),) : Column(
        // spacing: 20,
        children: [
          Expanded(
            child: openai.conversation.isEmpty ? Center(child: SingleChildScrollView(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Lottie.asset('assets/robot_animation.json'),
                Transform.translate(offset: Offset(0, -80), child: Text(dic.robot_sc))
              ],),
            ),) : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SizedBox(
                width: size.width,
                height: size.height - 150,
                child: ListView.builder(
                  controller: scrollController,
                  scrollDirection: Axis.vertical,
                  itemCount: openai.conversation.length,
                  itemBuilder: (context, index) {
                    if (index < 0 || index >= openai.conversation.length) return null;
                    final conv = openai.conversation[index];
                    final isUser = conv['sender'] == 'user';

                    if (conv['sender'] == 'waiting') {
                      return Directionality(
                        textDirection: TextDirection.ltr,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: SizedBox(
                                width: size.width * .1,
                                child: Container(
                                  width: size.width * .1,
                                  // padding: EdgeInsets.all(0),
                                  decoration: BoxDecoration(
                                    color: cs.secondary.withAlpha(25),
                                    borderRadius: BorderRadius.circular(45),
                                  ),

                                  child: Padding(
                                    padding: const EdgeInsets.all(0.0),
                                    child: Center(child: Lottie.asset('assets/loading.json')),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else if (conv['sender'] == 'done-waiting') {
                      return null;
                    }

                    return Directionality(
                      textDirection: isUser ? TextDirection.rtl : TextDirection.ltr,
                      child: Column(spacing: 0, mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text('${isUser ? userProfile.name! : dic.app_name}', style: TextStyle(fontSize: size.width * .03),),
                        ),
                        Container(
                          margin: EdgeInsets.only(bottom: 8),
                          width: size.width * .7,
                          decoration: BoxDecoration(
                            gradient: isUser ? LinearGradient(colors: [
                              cs.secondary.withAlpha(200), cs.secondary.withAlpha(150)
                            ], /*begin: Alignment.bottomLeft, end: Alignment.topRight*/) : LinearGradient(colors: [
                              cs.secondary.withAlpha(10), cs.secondary.withAlpha(25)
                            ]),

                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(8),
                              topLeft: Radius.circular(8),
                              bottomLeft: isUser ? Radius.circular(8) : Radius.circular(0),
                              bottomRight: isUser ? Radius.circular(0) : Radius.circular(8),
                            )
                          ),

                          padding: EdgeInsets.all(10),

                          child: Directionality(
                            textDirection: openai.isArabic(isUser ? conv['content'] : jsonDecode(conv['content'])['messages'][0]['content']) ? TextDirection.rtl : TextDirection.ltr,
                            child: MarkdownBody(
                              data: isUser ? conv['content'] : (jsonDecode(conv['content'])['messages'][0]['content']),
                              styleSheet: MarkdownStyleSheet(
                                p: TextStyle(color: isUser ? Colors.white : Colors.black,), // paragraph text
                                strong: TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),

                                em: TextStyle(fontStyle: FontStyle.italic, color: Colors.green), // *italic*
                              ),
                            ),
                          )
                          ,
                        ),
                      ],),
                    );
                  },
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 22),
            child: Row(
              spacing: 8,
              children: [
                Expanded(
                  child: TextField(
                    controller: inputController,
                    maxLines: null,
                    expands: false,
                    onSubmitted: (submittedText) {
                      sendOpenAIMessage(submittedText);
                      inputController.text = '';
                    },
                    decoration: InputDecoration(
                      // fillColor: HSLColor.fromColor(cs.surface).withLightness(.9).toColor(),
                      fillColor: cs.secondary.withAlpha(50),
                      hintText: dic.chatbot_input_hint
                    ),
                  ),
                ),

                GestureDetector(
                  onTap:() {
                    sendOpenAIMessage(inputController.text);
                    inputController.text = '';
                  },

                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: FaIcon(FontAwesomeIcons.paperPlane, color: cs.secondary,),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  final userProfile = UserProfile();
  String result = '';
  bool loading = true;

  Future<void> sendOpenAIMessage(String content) async {
    final messageContent = content.isEmpty ? 'أيش فيه وجبات فيها فطر؟' : content;
    setState(() {
      openai.conversation.add({
        'sender' : 'user',
        'content' : messageContent
      });

      openai.conversation.add({
        'sender' : 'waiting',
        // 'content' : messageContent
      });
    });
    try {
      print('--> openai conversation length ==> ${openai.conversation.length}');
      if (openai.conversation.length > 2)
        await scrollController.animateTo(scrollController.position.maxScrollExtent + MediaQuery.of(context).size.height / 2.0, duration: Durations.medium1, curve: Curves.easeIn,);
    } on Exception catch (e) {
      // TODO
    }
    // scrollController.jumpTo(scrollController.position.maxScrollExtent);
    final message = await openai.sendMessage(messageContent, userProfile.uid!);
    print('status ==> ${message.status}');
    if(message.status == OpenAIStatus.SUCCESFULL) {
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OpenAI API message :\n${message.content}'),));
      print(message.content);
      final response = jsonDecode(message.content) as Map<String, dynamic>;
      if (response['error']) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OpenAI API message :\n${message.content}'),));
        return;
      }

      setState(() {
        openai.conversation.removeAt(openai.conversation.length-1);
        openai.conversation.add({
          'sender' : 'system',
          'content' : jsonEncode(response)
        });
      });

      scrollController.animateTo(scrollController.position.maxScrollExtent  + MediaQuery.of(context).size.height / 2.0, duration: Durations.medium1, curve: Curves.easeIn,);
    } else {
      print('err  --->  ${message.content}');
      setState(() {
        openai.conversation.removeAt(openai.conversation.length-1);
        result = message.content;
      });
    }
  }


  @override
  void initState() {
    super.initState();


    inputController.addListener(() {
      // scrollController.animateTo(scrollController.position.maxScrollExtent, duration: Durations.medium1, curve: Curves.easeIn,);
    });

    userProfile.loadFromPref().then((_) => setState(() {
      loading = false;
      // sendOpenAIMessage('');
    }));
  }
}
