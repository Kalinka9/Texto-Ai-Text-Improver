import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:rxdart/rxdart.dart';

enum AnswerLength { same, shorten, expand }

class GPTRepository {
  final _gptController = ReplaySubject<String>();
  late OpenAI openAI;

  Stream<String> get gptResponseStream => _gptController.asBroadcastStream();
  void addToStream(String text) => _gptController.add(text);

  Future<void> sendRequest({
    required String apiKey,
    required String userMessage,
    required AnswerLength answerLength,
    required List<String> tones,
  }) async {
    openAI = OpenAI.instance.build(
      token: apiKey,
      baseOption: HttpSetup(
        receiveTimeout: const Duration(seconds: 10),
        connectTimeout: const Duration(seconds: 10),
      ),
      enableLog: true,
    );

    final systemMessage = '''
Follow these steps to answer user queries.

Step 1 - If the user text is not English, translate it into English. If you cannot detect the language, answer with "Could not detect the language" and quit.

Step 2 - Paraphrase and improve the English version from Step 1 ${_handleTones(tones)}, without changing the core message. Use natural language and phrases that a real person would use in everyday conversations. ${_handleLength(answerLength)}

I want you to only reply the improvements from Step 2 and nothing else, do not write explanations.
''';

    String response = await chatCompleteWithSSE(
      systemMessage: systemMessage,
      userMessage: userMessage,
    );

    addToStream(response);
  }

  Future<String> chatCompleteWithSSE({required String systemMessage, required String userMessage}) async {
    final request = ChatCompleteText(
      messages: [
        Messages(
          role: Role.system,
          content: systemMessage,
        ),
        Messages(
          role: Role.user,
          content: userMessage,
        ),
      ],
      maxToken: 200,
      model: GptTurboChatModel(),
    );

    ChatCTResponse? response = await openAI.onChatCompletion(request: request);
    if (response == null) return 'Failed to retrieve answer. Please try again.';
    return response.choices.last.message!.content;
  }

  String _handleLength(AnswerLength answerLength) {
    switch (answerLength) {
      case AnswerLength.shorten:
        return 'Make the rephrased message shorter than the original.';
      case AnswerLength.expand:
        return 'Make the rephrased message longer than the original.';
      case AnswerLength.same:
        return 'The rephrased message should have the same length as the original.';
    }
  }

  String _handleTones(List<String> tones) {
    if (tones.isNotEmpty) {
      return 'in a ${tones.join(' and ')} tone';
    }
    return '';
  }
}
