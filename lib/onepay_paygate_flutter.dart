import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onepay_paygate_flutter/src/main_view.dart';

enum OnepayCurrency { vnd, usd }

enum OnePayErrorCase {
  MOBILE_NOT_APP_BANKING, // app mobile banking doesn't install or not config in LSApplicationQueriesSchemes
  NOT_CONNECT_WEB_ONEPAY, // app not connect web onepay.Please check the information set onepay sent.
  NOT_FOUND_APP_BANKING, // App banking isn't exist. Contact the onepay developer with information of the message field in error.
  WEB_ONEPAY_STATUS_500, // app not connect web onepay.Contact onepay for support.
}

class OPErrorResult {
  OnePayErrorCase errorCase;

  OPErrorResult({required this.errorCase});
}

class OPPaymentEntity {
  String version = VERSION_PAYGATE;
  double amount;
  String orderInformation;
  OnepayCurrency currency;
  String accessCode;
  String merchant;
  String hashKey;
  String urlSchemes;
  String command = COMMAND_PAYGATE;
  String? customerPhone;
  String? customerEmail;
  String? customerId;
  late String returnUrl = "$urlSchemes://onepay/";

  static const VERSION_PAYGATE = "2";
  static const COMMAND_PAYGATE = "pay";
  static const AGAIN_LINK = "https://localhost/again_link";
  static const TICKET_NO = "10.2.20.1";
  static const LINK_PAYGATE = "https://mtf.onepay.vn/paygate/vpcpay.op";
  //static const LINK_PAYGATE = "https://onepay.vn/paygate/vpcpay.op";
  static const VPC_THEME = "general";

  OPPaymentEntity({
    required this.amount,
    required this.orderInformation,
    required this.currency,
    required this.accessCode,
    required this.merchant,
    required this.hashKey,
    required this.urlSchemes,
    this.customerPhone,
    this.customerEmail,
    this.customerId,
  });

  String createUrlPayment() {
    var code = "${DateTime.now().millisecondsSinceEpoch}";
    var title = merchant;
    var amountString = "${(amount * 100).toInt()}";
    var returnURL = returnUrl;
    var ticketNo = TICKET_NO;
    // print(Platform.localeName);
    var languageString = Platform.localeName.contains("vi") ? "vn" : "en";
    var queries = {
      "vpc_Version": version,
      "vpc_Command": command,
      "vpc_AccessCode": accessCode,
      "vpc_Merchant": merchant,
      "vpc_Locale": languageString,
      "vpc_ReturnURL": returnURL,
      "vpc_MerchTxnRef": code,
      "vpc_OrderInfo": orderInformation,
      "vpc_Amount": amountString,
      "vpc_TicketNo": ticketNo,
      "Title": title,
      "vpc_Currency": currency.name.toUpperCase(),
      "vpc_Theme": VPC_THEME,
      "AgainLink": AGAIN_LINK,
    };
    if (customerPhone != null) {
      queries["vpc_Customer_Phone"] = customerPhone!;
    }
    if (customerEmail != null) {
      queries["vpc_Customer_Email"] = customerEmail!;
    }
    if (customerId != null) {
      queries["vpc_Customer_Id"] = customerId!;
    }
    queries["vpc_SecureHash"] = secureHashQueries(queries, hashKey);
    var queryString = queries.entries.map((e) => "${e.key}=${e.value}").join("&");
    // var uri = Uri.parse("$LINK_PAYGATE?$queryString");
    // var encodeQueryString = Uri.encodeQueryComponent(queryString);
    var uri = Uri.encodeFull("$LINK_PAYGATE?$queryString");
    // var uri = Uri.encodeComponent("$LINK_PAYGATE?$queryString");
    // Uri.encodeComponent(component)
    return uri;
  }

  String secureHashQueries(Map<String, String> queries, String hashKeyCustomer) {
    var key = <int>[];
    var hashKeyCharacters = hashKeyCustomer.characters;
    for (var i = 0; i < hashKeyCharacters.length; i += 2) {
      var str = "${hashKeyCharacters.characterAt(i)}";
      if (i + 1 < hashKeyCharacters.length) {
        str += "${hashKeyCharacters.characterAt(i + 1)}";
      }
      key.add(int.parse(str, radix: 16));
    }
    // var key = utf8.encode(hashKeyCustomer);
    // print("$hashKeyCustomer: $key");
    // print(int.parse(hashKeyCustomer, radix: 16));
    var mapQueries = SplayTreeMap<String, String>.from(queries, (a, b) => a.compareTo(b));
    var queryString = mapQueries.entries
        .map((e) {
          if (e.key.startsWith("vpc_")) {
            return "${e.key}=${e.value}";
          }
          return "";
        })
        .where((element) => element.isNotEmpty)
        .join("&");
    var queryStringData = utf8.encode(queryString);
    var hmac = Hmac(sha256, key);
    sha256.convert(queryStringData);
    var digest = hmac.convert(queryStringData);
    return digest.toString().toUpperCase();
  }
}

class OPPaymentResult {
  bool isSuccess;
  String? amount;
  String? card;
  String? cardNumber;
  String? command;
  String? merchTxnRef;
  String? merchant;
  String? message;
  String? orderInfo;
  String? payChannel;
  String? transactionNo;
  String? version;

  OPPaymentResult({
    required this.isSuccess,
    this.amount,
    this.card,
    this.cardNumber,
    this.command,
    this.merchTxnRef,
    this.merchant,
    this.message,
    this.orderInfo,
    this.payChannel,
    this.transactionNo,
    this.version,
  });
}

typedef OnPayResult = void Function(OPPaymentResult result);
typedef OnPayFail = void Function(OPErrorResult error);

class OnePayPaygate {
  static const MethodChannel _channel = MethodChannel('onepay_paygate_flutter');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<void> openCustomURL(String url) async {
    return await _channel.invokeMethod("openCustomURL", [url]);
  }

  static Future<int> getAndroidSdkInt() async {
    if (!Platform.isAndroid) return -1;
    try {
      final sdk = await _channel.invokeMethod<int>('getSdkInt');
      return sdk ?? -1;
    } catch (e) {
      return -1;
    }
  }

  static void open({required BuildContext context, required OPPaymentEntity entity, OnPayResult? onPayResult, OnPayFail? onPayFail}) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => OnePayPaygateView(paymentEntity: entity, onPayResult: onPayResult, onPayFail: onPayFail)));
  }
}
