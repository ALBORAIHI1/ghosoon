import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  WebViewController? _webViewController;
  bool _isConnected = true;
  bool _isLoading = true;
  bool _isError = false;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _checkInternetConnection();
    _listenForConnectivityChanges();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _initializeWebView() async {
    final controller = WebViewController();

    await controller.clearCache(); // Optional: Clear cache if needed
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _isError = false; // Reset error state
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false; // Hide loading indicator
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _isError = true; // Show custom error screen
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            if (!_isConnected && !request.url.startsWith("file://")) {
              _showNoInternetToast();
              return NavigationDecision
                  .prevent; // Block navigation for dynamic requests
            }
            return NavigationDecision.navigate; // Allow navigation
          },
        ),
      )
      ..loadRequest(Uri.parse(
          'https://gosoun.com')); // Replace with your OpenCart store URL

    setState(() {
      _webViewController = controller;
    });
  }

  Future<void> _checkInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _isConnected = false;
        _isError = false; // Avoid showing error screen, show cached content
        _isLoading = false;
      });
    } else {
      setState(() {
        _isConnected = true;
        _isError = false;
      });
      if (_webViewController != null) {
        _webViewController!.reload(); // Reload when internet is restored
      }
    }
  }

  void _listenForConnectivityChanges() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      _checkInternetConnection();
    });
  }

  void _showNoInternetToast() {
    Fluttertoast.showToast(
      msg: "لا يوجد اتصال بالإنترنت",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  Future<bool> _onWillPop() async {
    if (_webViewController != null && await _webViewController!.canGoBack()) {
      _webViewController!.goBack();
      return false;
    } else {
      // Show a dialog to confirm if the user wants to close the app
      bool? shouldClose = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('إغلاق التطبيق'),
          content: Text('هل تريد إغلاق التطبيق؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('لا'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('نعم'),
            ),
          ],
        ),
      );
      return shouldClose ?? false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              // Show WebView with cached content when online or offline
              if (!_isLoading && !_isError)
                WebViewWidget(
                  controller: _webViewController ??
                      WebViewController(), // Fallback for WebViewController
                ),
              if (_isLoading)
                Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF4b8402),
                  ),
                ),
              if (!_isConnected && _isError)
                Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF4b8402),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
