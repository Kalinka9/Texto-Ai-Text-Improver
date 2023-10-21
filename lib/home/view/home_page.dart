import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:ai_text_improver_app/home/home.dart';
import 'package:ai_text_improver_app/widgets/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum SampleItem { enterApiKey, about }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _textController = TextEditingController();
  final _apiKeyController = TextEditingController();

  double _slider1Value = 0.5;
  double _slider2Value = 0.5;
  double _slider3Value = 0.5;

  @override
  void dispose() {
    _apiKeyController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        switch (state.status) {
          case HomeStatus.initial:
            return const Scaffold(body: Center(child: Text('Please wait...')));
          case HomeStatus.loading:
            return Stack(
              children: [
                _scaffold(context, state),
                const Opacity(
                  opacity: 0.5,
                  child: ModalBarrier(dismissible: false, color: Colors.black),
                ),
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ],
            );
          case HomeStatus.success:
            return _scaffold(context, state);
          case HomeStatus.failure:
            return const Scaffold(body: Center(child: Text('Failed loading page')));
        }
      },
    );
  }

  Widget _scaffold(BuildContext context, HomeState state) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: _appBar(context, state),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: ListView(
            physics: const ClampingScrollPhysics(),
            children: [
              _inputCard(size),
              if (state.resultText.isNotEmpty || state.errorText.isNotEmpty) const SizedBox(height: 15),
              if (state.resultText.isNotEmpty) _resultCard(size, state.resultText),
              if (state.errorText.isNotEmpty) _errorCard(size, state.errorText),
              const SizedBox(height: 15),
              _tonesCard(size),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (state.apiKey.trim().isEmpty) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please provide an API key (upper right corner)'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                if (_textController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter some text to improve.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                FocusScope.of(context).unfocus();
                context.read<HomeCubit>().improve(
                      userMessage: _textController.text,
                      formalValue: _slider1Value,
                      assertiveValue: _slider2Value,
                      expandValue: _slider3Value,
                    );
              },
              child: const Text(
                'Improve!',
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _appBar(BuildContext context, HomeState state) {
    return AppBar(
      title: const Text('AI Text Improver'),
      actions: [
        IconButton(
            onPressed: () {
              _textController.text = '';
              FocusScope.of(context).unfocus();

              _slider1Value = 0.5;
              _slider2Value = 0.5;
              _slider3Value = 0.5;

              context.read<HomeCubit>().reset();
            },
            icon: const Icon(Icons.refresh)),
        PopupMenuButton<SampleItem>(
          onSelected: (value) {
            switch (value) {
              case SampleItem.enterApiKey:
                _showTextInputDialog(context, state);
                break;
              case SampleItem.about:
                _showAboutDialog(context, state);
                break;
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<SampleItem>(
              value: SampleItem.enterApiKey,
              child: Text('Enter API key'),
            ),
            const PopupMenuItem<SampleItem>(
              value: SampleItem.about,
              child: Text('About'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showTextInputDialog(BuildContext context, HomeState state) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter OpenAI API key'),
          content: TextField(
            controller: _apiKeyController..text = state.apiKey,
            decoration: InputDecoration(
              hintText: 'sk-',
              suffixIcon: IconButton(
                onPressed: _apiKeyController.clear,
                icon: const Icon(Icons.clear),
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                context.read<HomeCubit>().setApiKey(_apiKeyController.text);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAboutDialog(BuildContext context, HomeState state) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    if (!mounted) return;

    return showAboutDialog(
      context: context,
      applicationIcon: const FlutterLogo(size: 32),
      applicationName: 'AI Text Improver',
      applicationVersion: packageInfo.version,
      applicationLegalese: '\u{a9} 2023 Denis Engelhardt',
      children: const [
        Padding(
          padding: EdgeInsets.only(top: 15),
          child: Text('A GPT based AI text improvement tool.'),
        ),
      ],
    );
  }

  Widget _inputCard(Size size) {
    return Stack(children: [
      TextField(
        controller: _textController,
        maxLines: 6,
        maxLength: 2000,
        textInputAction: TextInputAction.newline,
        keyboardType: TextInputType.multiline,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          alignLabelWithHint: true,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[300]!, width: 4),
            borderRadius: BorderRadius.circular(5),
          ),
          hintText: 'Enter text in any language. Feel free to use any formatting.',
          hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
          floatingLabelAlignment: FloatingLabelAlignment.start,
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.purple, width: 2),
            borderRadius: BorderRadius.circular(5),
          ),
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
      Align(
        alignment: Alignment.topRight,
        child: IconButton(
            onPressed: () {
              _textController.text = '';
              FocusScope.of(context).unfocus();
            },
            icon: const Icon(Icons.clear)),
      ),
    ]);
  }

  Widget _resultCard(Size size, String text) {
    return Container(
      padding: const EdgeInsets.only(top: 12.0, left: 12.0, right: 12.0, bottom: 0),
      alignment: Alignment.topLeft,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(
          Radius.circular(5),
        ),
        border: Border.all(
          color: Colors.purple,
          width: 1,
        ),
        color: Colors.purple.withOpacity(0.15),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: text)).then((_) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied text to clipboard'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    });
                  },
                  icon: const Icon(
                    Icons.copy_outlined,
                    color: Colors.purple,
                    size: 22.0,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _errorCard(Size size, String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.red, fontSize: 14),
    );
  }

  Widget _tonesCard(Size size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Tone',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        CustomSlider(
          minCaption: 'Casual',
          maxCaption: 'Formal',
          value: _slider1Value,
          color: Colors.purple,
          onChanged: (value) {
            setState(() {
              _slider1Value = value;
            });
          },
        ),
        CustomSlider(
          minCaption: 'Friendly',
          maxCaption: 'Assertive',
          value: _slider2Value,
          color: Colors.orange,
          onChanged: (value) {
            setState(() {
              _slider2Value = value;
            });
          },
        ),
        CustomSlider(
          minCaption: 'Shorten',
          maxCaption: 'Expand',
          value: _slider3Value,
          color: Colors.green,
          onChanged: (value) {
            setState(() {
              _slider3Value = value;
            });
          },
        ),
      ],
    );
  }
}
