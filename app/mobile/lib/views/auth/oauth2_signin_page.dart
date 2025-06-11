import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../../settings.dart';
import '../auth/welcome_view.dart';
import 'package:mobile/services/token_repository.dart';

class OAuth2SignInPage extends StatefulWidget {
  const OAuth2SignInPage({super.key});

  @override
  State<OAuth2SignInPage> createState() => _OAuth2SignInPageState();
}

class _OAuth2SignInPageState extends State<OAuth2SignInPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (req) {
            final uri = Uri.parse(req.url);
            if (uri.path == '/auth/oauth2/success' &&
                uri.queryParameters['token'] != null) {
              final token = uri.queryParameters['token']!;
              TokenRepository().saveToken(token).then((_) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const WelcomeView()),
                      (route) => false,
                );
              });
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(
        Uri.parse('${Settings.getServerUrl()}/oauth2/authorization/google'),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logowanie Google'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}