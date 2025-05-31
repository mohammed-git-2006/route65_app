

import 'dart:convert';
import 'package:http/http.dart' as http;

enum OpenAIStatus {
  ERROR,
  SUCCESFULL
}

class MessageResult {
  late OpenAIStatus status;
  late String content;

  MessageResult(this.status, this.content);
}

class OpenAIAPI {
  List<Map<String, dynamic>> conversation = [];

  void saveMessageToChat(String message, String response) {
    conversation.add({
      'sender' : 'user',
      'content' : message
    });

    conversation.add({
      'sender' : 'system',
      'content' : response
    });
  }

  bool isArabic(String content) {
    final arabicRegExp = RegExp(r'[\u0600-\u06FF]');
    return arabicRegExp.hasMatch(content);
  }

  Future<MessageResult> sendMessage(String  message, String id) async {
    try {
      print('sending message to openai');
      final Uri url = Uri.parse('https://www.route-65-dashboard.com/api/gpt');
      final body = {
        'message' : message,
        'id' : id
      };

      final response = await http.post(url, body: body);
      print('got resposne from server! ${response.body}');
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (decoded.containsKey('server_error')) {
        print('found server error');
        return MessageResult(OpenAIStatus.ERROR, 'Server-Error');
      }

      print('no error found');

      return MessageResult(OpenAIStatus.SUCCESFULL, response.body);
    } catch (err) {
      print('[Code Level] error found $err');
      return MessageResult(OpenAIStatus.ERROR, '$err');
    }
  }
}