import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wechat_bridge/wechat_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MethodChannelWechatBridge platform;
  const MethodChannel channel = MethodChannel('wechat_bridge');

  setUp(() {
    platform = MethodChannelWechatBridge();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'isInstalled':
          return true;
        case 'isSupportApi':
          return true;
        case 'isSupportStateApi':
          return false;
        case 'openWechat':
          return true;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('isInstalled', () async {
    expect(await platform.isInstalled(), true);
  });

  test('isSupportApi', () async {
    expect(await platform.isSupportApi(), true);
  });

  test('isSupportStateApi', () async {
    expect(await platform.isSupportStateApi(), false);
  });

  test('openWechat', () async {
    expect(await platform.openWechat(), true);
  });
}
