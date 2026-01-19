import 'dart:convert';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../onepay_paygate_flutter.dart';

class OnePayPaygateView extends StatefulWidget {
  OPPaymentEntity paymentEntity;
  OnPayResult? onPayResult;
  OnPayFail? onPayFail;

  OnePayPaygateView({
    super.key,
    required this.paymentEntity,
    this.onPayResult,
    this.onPayFail,
  });

  @override
  _OnePayPaygateViewState createState() => _OnePayPaygateViewState();
}

class _OnePayPaygateViewState extends State<OnePayPaygateView> {
  late final WebViewController _webViewController;

  final _appLinks = AppLinks(); // AppLinks is singleton

  @override
  void initState() {
    super.initState();

    // Subscribe to all events (initial link and further)
    _appLinks.uriLinkStream.listen((uri) {
      handleDeeplink(uri.toString());
    });

    var url = widget.paymentEntity.createUrlPayment();

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (JavaScriptMessage message) async {
          final dataUrl = message.message;
          await _handleBase64ImageFromJs(dataUrl);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {
            if (url.startsWith(widget.paymentEntity.returnUrl)) {
              handlePaymentResult(url);
            }
          },
          onPageFinished: (String url) {
            // Inject JS AndroidHandleDownload giống Android
            _injectBlobHookJs();
          },
          onHttpError: (HttpResponseError error) {},
          onWebResourceError: (WebResourceError error) {
            var errorResult = OPErrorResult(errorCase: OnePayErrorCase.NOT_CONNECT_WEB_ONEPAY);
            widget.onPayFail?.call(errorResult);
          },
          onNavigationRequest: (NavigationRequest request) async {
            var url = request.url;
            if (url.startsWith('data:image/png;base64') || url.contains('data:image/png;base64,')) {
              final commaIndex = url.indexOf(',');
              final base64Str = commaIndex != -1 ? url.substring(commaIndex + 1) : url;
              try {
                final bytes = base64Decode(base64Str);

                final permissionStatus = await _requestSaveImagePermission();
                if (!permissionStatus.isGranted) {
                  debugPrint('Permission denied for saving image');
                  return NavigationDecision.prevent;
                }

                await ImageGallerySaverPlus.saveImage(
                  bytes,
                  name: 'qrcode_${DateTime.now().millisecondsSinceEpoch}', // gallery_saver tự thêm đuôi
                  quality: 100,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Download QR code successfully!"),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e, s) {
                debugPrint('Download QR error: $e\n$s');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Download QR code fail, please try again later!"),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }

              // Chặn WebView khỏi việc navigate tới data URL
              return NavigationDecision.prevent;
            }

            if (url.startsWith('blob:')) {
              final safeUrl = url.replaceAll(r'\', r'\\').replaceAll("'", r"\'");

              await _webViewController.runJavaScript(
                "window.AndroidHandleDownload && window.AndroidHandleDownload('$safeUrl');",
              );
              // Chặn WebView khỏi việc navigate tới blob:
              return NavigationDecision.prevent;
            }
            if (url.toLowerCase().startsWith(widget.paymentEntity.returnUrl.toLowerCase())) {
              handlePaymentResult(url);
              return NavigationDecision.prevent;
            }
            if (url.startsWith(OPPaymentEntity.AGAIN_LINK)) {
              return NavigationDecision.prevent;
            }
            if (!url.startsWith("http") && url != "about:blank") {
              openCustomUrl(url);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  //Inject JS để download anh
  void _injectBlobHookJs() {
    const js = '''
      (function() {
        window.AndroidHandleDownload = function(url) {
          try {
            if (!url) return;
            // Nếu đã là data:image/png;base64
            if (url.indexOf('data:image/png;base64') === 0) {
              FlutterBridge.postMessage(url);
              return;
            }
            // Nếu là blob: -> convert sang dataURL
            if (url.indexOf('blob:') === 0) {
              var xhr = new XMLHttpRequest();
              xhr.open('GET', url, true);
              xhr.responseType = 'blob';
              xhr.onload = function() {
                if (this.status === 200) {
                  var reader = new FileReader();
                  reader.onloadend = function() {
                    try {
                      FlutterBridge.postMessage(this.result);
                    } catch (ex) {}
                  };
                  reader.readAsDataURL(this.response);
                }
              };
              xhr.send();
              return;
            }
          } catch (e) {}
        };
      })();
    ''';

    _webViewController.runJavaScript(js);
  }

  //Handle image from base 64
  Future<void> _handleBase64ImageFromJs(String dataUrl) async {
    try {
      final commaIndex = dataUrl.indexOf(',');
      final base64Str = commaIndex != -1 ? dataUrl.substring(commaIndex + 1) : dataUrl;

      final bytes = base64Decode(base64Str);

      final permissionStatus = await _requestSaveImagePermission();
      if (!permissionStatus.isGranted) {
        debugPrint('Permission denied for saving image (JS bridge)');
        return;
      }

      await ImageGallerySaverPlus.saveImage(
        bytes,
        name: 'qrcode_${DateTime.now().millisecondsSinceEpoch}',
        quality: 100,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Download QR code successfully!"),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, s) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Download QR code fail, please try again later!"),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Xử lý xin quyền lưu ảnh
  Future<PermissionStatus> _requestSaveImagePermission() async {
    if (Platform.isIOS) {
      return PermissionStatus.granted;
    } else {
      var sdk = await OnePayPaygate.getAndroidSdkInt();
      if (sdk <= 32) {
        final statuses = await <Permission>[Permission.storage].request();
        final status = statuses[Permission.storage];
        debugPrint('SaveImagePermission (Android <=32): $status');
        return status ?? PermissionStatus.denied;
      } else {
        final statuses = await <Permission>[Permission.photos].request();
        final status = statuses[Permission.photos];
        debugPrint('SaveImagePermission (Android 33+): $status');
        return status ?? PermissionStatus.denied;
      }
    }
  }

  void handleDeeplink(String? deeplink) {
    if (deeplink == null) {
      return;
    }
    if (deeplink.contains(widget.paymentEntity.returnUrl)) {
      var uri = Uri.parse(deeplink);
      var encryptLink = uri.queryParameters["deep_link"];
      if (encryptLink != null && encryptLink.isNotEmpty) {
        var base64Decoder = const Base64Decoder();
        var deeplinkUri = Uri.parse("${base64Decoder.convert(encryptLink)}");
        var url = deeplinkUri.queryParameters["url"];
        if (url != null && url.isNotEmpty) {
          _webViewController.loadRequest(Uri.parse(url));
        }
        return;
      }
      var url = uri.queryParameters["url"];
      if (url != null && url.isNotEmpty) {
        _webViewController.loadRequest(Uri.parse(url));
        return;
      }
      _webViewController.loadRequest(uri);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: WebViewWidget(controller: _webViewController),
      ),
    );
  }

  void handlePaymentResult(String url) {
    var uri = Uri.parse(url);
    var queries = uri.queryParameters;
    var code = queries["vpc_TxnResponseCode"];
    var isSuccess = false;
    if (code != null && code == "0") {
      isSuccess = true;
    }
    Navigator.pop(context);
    widget.onPayResult?.call(OPPaymentResult(
      isSuccess: isSuccess,
      amount: queries["vpc_Amount"],
      card: queries["vpc_Card"],
      cardNumber: queries["vpc_CardNum"],
      command: queries["vpc_Command"],
      merchTxnRef: queries["vpc_MerchTxnRef"],
      merchant: queries["vpc_Merchant"],
      message: queries["vpc_Message"],
      orderInfo: queries["vpc_OrderInfo"],
      payChannel: queries["vpc_PayChannel"],
      transactionNo: queries["vpc_TransactionNo"],
      version: queries["vpc_Version"],
    ));
  }

  void openCustomUrl(String url) {
    OnePayPaygate.openCustomURL(url);
  }
}
