// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing


import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:wechat_bridge/wechat_bridge.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('isInstalled test', (WidgetTester tester) async {
    final platform = WechatBridgePlatform.instance;
    final bool isInstalled = await platform.isInstalled();
    // isInstalled depends on whether WeChat is installed on the device
    expect(isInstalled, isA<bool>());
  });
}
