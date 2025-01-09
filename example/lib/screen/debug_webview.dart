import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class DebugWebviewScreen extends StatelessWidget {
  const DebugWebviewScreen({
    super.key,
    required this.initialUrl,
  });

  final String initialUrl;

  static void open(
    BuildContext context, {
    required String initialUrl,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return DebugWebviewScreen(initialUrl: initialUrl);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const CloseButton(),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri(initialUrl.toString()),
        ),
        initialSettings: InAppWebViewSettings(
          javaScriptCanOpenWindowsAutomatically: true,
          supportMultipleWindows: true,
        ),
        gestureRecognizers: {
          Factory(() => EagerGestureRecognizer()),
        },
      ),
    );
  }
}
