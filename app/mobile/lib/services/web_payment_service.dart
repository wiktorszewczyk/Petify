import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebPaymentService {
  static WebPaymentService? _instance;
  factory WebPaymentService() => _instance ??= WebPaymentService._();
  WebPaymentService._();

  /// Otwiera płatność w natywnym WebView zamiast zewnętrznej przeglądarki
  Future<WebPaymentResult?> processPayment({
    required BuildContext context,
    required String paymentUrl,
    required String successUrl,
    required String cancelUrl,
  }) async {
    try {
      dev.log('Opening payment WebView for URL: $paymentUrl');

      final result = await Navigator.of(context).push<WebPaymentResult>(
        MaterialPageRoute(
          builder: (context) => WebPaymentPage(
            paymentUrl: paymentUrl,
            successUrl: successUrl,
            cancelUrl: cancelUrl,
          ),
        ),
      );

      dev.log('WebView payment result: ${result?.status}');
      return result;
    } catch (e) {
      dev.log('WebView payment failed: $e');
      throw Exception('Nie udało się otworzyć płatności: $e');
    }
  }
}

class WebPaymentPage extends StatefulWidget {
  final String paymentUrl;
  final String successUrl;
  final String cancelUrl;

  const WebPaymentPage({
    Key? key,
    required this.paymentUrl,
    required this.successUrl,
    required this.cancelUrl,
  }) : super(key: key);

  @override
  State<WebPaymentPage> createState() => _WebPaymentPageState();
}

class _WebPaymentPageState extends State<WebPaymentPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            dev.log('WebView started loading: $url');
            _checkForRedirect(url);
          },
          onPageFinished: (String url) {
            dev.log('WebView finished loading: $url');
            setState(() => _isLoading = false);
            _checkForRedirect(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            dev.log('WebView navigation request: ${request.url}');
            _checkForRedirect(request.url);
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _checkForRedirect(String url) {
    dev.log('Checking redirect URL: $url');

    // Sprawdź czy URL zawiera informacje o zakończeniu płatności
    if (url.contains('success') || url.contains('completed') ||
        url.contains('status=success') || url.contains('payment_status=completed') ||
        url.contains('petify.com/payment/success')) {
      _returnResult(WebPaymentStatus.success);
    } else if (url.contains('cancel') || url.contains('error') ||
        url.contains('status=cancel') || url.contains('payment_status=cancelled') ||
        url.contains('petify.com/payment/cancel')) {
      _returnResult(WebPaymentStatus.cancelled);
    } else if (url.contains(widget.successUrl)) {
      _returnResult(WebPaymentStatus.success);
    } else if (url.contains(widget.cancelUrl)) {
      _returnResult(WebPaymentStatus.cancelled);
    }
  }

  bool _hasReturned = false;

  void _returnResult(WebPaymentStatus status) {
    if (mounted && !_hasReturned) {
      _hasReturned = true;
      dev.log('Returning payment result: $status');
      Navigator.of(context).pop(WebPaymentResult(status: status));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Płatność'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _returnResult(WebPaymentStatus.cancelled),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

class WebPaymentResult {
  final WebPaymentStatus status;
  final String? errorMessage;

  WebPaymentResult({
    required this.status,
    this.errorMessage,
  });
}

enum WebPaymentStatus {
  success,
  cancelled,
  error,
}