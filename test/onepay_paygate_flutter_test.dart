import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepay_paygate_flutter/onepay_paygate_flutter.dart';

void main() {
  const MethodChannel channel = MethodChannel('onepay_paygate_flutter');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    // expect(await OnepayPaygateFlutter.platformVersion, '42');
  });
}
