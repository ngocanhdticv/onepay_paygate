import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:uni_links/uni_links.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../onepay_paygate_flutter.dart';

class OnePayPaygateView extends StatefulWidget {
  OPPaymentEntity paymentEntity;
  OnPayResult? onPayResult;
  OnPayFail? onPayFail;

  OnePayPaygateView({Key? key, required this.paymentEntity, this.onPayResult, this.onPayFail}) : super(key: key);

  @override
  _OnePayPaygateViewState createState() => _OnePayPaygateViewState(paymentEntity: paymentEntity, onPayResult: onPayResult, onPayFail: onPayFail,);
}

class _OnePayPaygateViewState extends State<OnePayPaygateView> {
  OPPaymentEntity paymentEntity;
  OnPayResult? onPayResult;
  OnPayFail? onPayFail;
  _OnePayPaygateViewState({required this.paymentEntity, this.onPayResult, this.onPayFail});
  String? _deeplink;
  StreamSubscription? _subscription;
  WebViewController? _webViewController;

  @override
  void initState() {
    _subscription = linkStream.listen((event) {
      handleDeeplink(event);
    });
    initUniLinks().then((value) {
      // handleDeeplink(value);
      // setState(() {
      //   _deeplink = value;
      // });
    });
    super.initState();
  }

  Future<String?> initUniLinks() async {
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      final initialLink = await getInitialLink();
      // Parse the link and warn the user, if it is not correct,
      // but keep in mind it could be `null`.
      return initialLink;
    } on PlatformException {
      // Handle exception by warning the user their action did not succeed
      // return?
      return "";
    }
  }

  void handleDeeplink(String? deeplink) {
    // var uri = Uri.parse(deeplink);
    if (deeplink == null) {
      return;
    }
    if (deeplink.contains(paymentEntity.returnUrl)) {
      var uri = Uri.parse(deeplink);
      var encryptLink = uri.queryParameters["deep_link"];
      if (encryptLink != null && encryptLink.isNotEmpty) {
        var base64Decoder = Base64Decoder();
        var deeplinkUri = Uri.parse("${base64Decoder.convert(encryptLink)}");
        var url = deeplinkUri.queryParameters["url"];
        if (url != null && url.isNotEmpty) {
          _webViewController?.loadUrl(url);
        }
        return;
      }
      var url = uri.queryParameters["url"];
      if (url != null && url.isNotEmpty) {
        _webViewController?.loadUrl(url);
        return;
      }
      _webViewController?.loadUrl(uri.toString());
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _subscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: WebView(
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (WebViewController webViewController) {
            var url = paymentEntity.createUrlPayment();
            _webViewController = webViewController;
            webViewController.loadUrl(url);
          },
          onPageStarted: (url) {
            if (url.startsWith(paymentEntity.returnUrl)) {
              handlePaymentResult(url);
            }
          },
          onWebResourceError: (error) {
            var errorResult = OPErrorResult(errorCase: OnePayErrorCase.NOT_CONNECT_WEB_ONEPAY);
            onPayFail?.call(errorResult);
          },
          onPageFinished: (url) {

          },
          navigationDelegate: (NavigationRequest request) {
            var url = request.url;
            if (url.toLowerCase().startsWith(paymentEntity.returnUrl.toLowerCase())) {
              handlePaymentResult(url);
              return NavigationDecision.prevent;
            }
            if (url.startsWith(OPPaymentEntity.AGAIN_LINK)) {
              return NavigationDecision.prevent;
            }
            if (!url.startsWith("http")) {
              openCustomUrl(url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },

        ),
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
    onPayResult?.call(OPPaymentResult(
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
        version: queries["vpc_Version"]
    ));

  }

  void openCustomUrl(String url) {
    OnePayPaygate.openCustomURL(url);
  }
}