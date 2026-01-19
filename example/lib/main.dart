import 'package:flutter/material.dart';
import 'package:onepay_paygate_flutter/onepay_paygate_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'OnePay Paygate Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _amount = "10000";

  void _createPayment() {
    if (_amount.isEmpty) {
      return;
    }
    // // var ACCESS_CODE_PAYGATE = "22772CEF"; // Onepay send for merchant
    // var ACCESS_CODE_PAYGATE = "6BEB2546"; // Onepay send for merchant
    // var MERCHANT_PAYGATE = "TESTONEPAY"; //  Merchant register with onepay
    // var HASH_KEY = "6D0870CDE5F24F34F3915FB0045120DB"; // Onepay send for merchant
    // var URL_SCHEMES = "merchantappscheme"; // get CFBundleURLSchemes in Info.plist

    // OnePay Paygate test config (the same as your example)
    const ACCESS_CODE_PAYGATE = "6BEB2546";
    const MERCHANT_PAYGATE = "TESTMERCHANT";
    const HASH_KEY = "6D0870CDE5F24F34F3915FB0045120DB";
    const URL_SCHEMES = "merchantappscheme"; // must match Android/iOS deeplink scheme
    var entity = OPPaymentEntity(
        amount: double.parse(_amount),
        orderInformation: "$MERCHANT_PAYGATE test",
        currency: OnepayCurrency.vnd,
        accessCode: ACCESS_CODE_PAYGATE,
        merchant: MERCHANT_PAYGATE,
        hashKey: HASH_KEY,
        urlSchemes: URL_SCHEMES);
    OnePayPaygate.open(context: context, entity: entity,
      onPayResult: (OPPaymentResult result) {
          print("result: ${result.toString()}");
          if (result.isSuccess) {
            showDialog(context: context, builder: (context) => const AlertDialog(title: Text("Thông báo"), content: Text("Thanh toán thành công"),));
          } else {
            showDialog(context: context, builder: (context) => AlertDialog(title: const Text("Thông báo"), content: Text(result.message ?? "Thanh toán không thành công"),));
          }
        },
      onPayFail: (error) {
        showDialog(context: context, builder: (context) => AlertDialog(title: const Text("Lỗi"), content: Text(error.errorCase.name),));
      });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: TextFormField(
                initialValue: _amount,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'Nhập số tiền thanh toán:',
                ),
                onChanged: (value) {
                  setState(() {
                    _amount = value;
                  });
                },
              ),
            ),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: ElevatedButton(
                child: const Text('Thanh toán'),
                onPressed: _createPayment,
              ),
            )
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
