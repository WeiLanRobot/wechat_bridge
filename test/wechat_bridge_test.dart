import 'package:flutter_test/flutter_test.dart';
import 'package:wechat_bridge/wechat_bridge.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockWechatBridgePlatform
    with MockPlatformInterfaceMixin
    implements WechatBridgePlatform {
  @override
  Future<void> registerApp({
    required String appId,
    required String? universalLink,
  }) =>
      Future.value();

  @override
  Stream<WechatReq> reqStream() => const Stream.empty();

  @override
  Stream<WechatResp> respStream() => const Stream.empty();

  @override
  Stream<WechatQrauthResp> qrauthRespStream() => const Stream.empty();

  @override
  Future<void> handleInitialWXReq() => Future.value();

  @override
  Future<bool> isInstalled() => Future.value(true);

  @override
  Future<bool> isSupportApi() => Future.value(true);

  @override
  Future<bool> isSupportStateApi() => Future.value(false);

  @override
  Future<bool> openWechat() => Future.value(true);

  @override
  Future<void> auth({
    required List<String> scope,
    String? state,
    int type = 0,
  }) =>
      Future.value();

  @override
  Future<void> startQrauth({
    required String appId,
    required List<String> scope,
    required String noncestr,
    required String ticket,
  }) =>
      Future.value();

  @override
  Future<void> stopQrauth() => Future.value();

  @override
  Future<void> openUrl({required String url}) => Future.value();

  @override
  Future<void> openRankList() => Future.value();

  @override
  Future<void> shareText({
    required int scene,
    required String text,
  }) =>
      Future.value();

  @override
  Future<void> shareImage({
    required int scene,
    String? title,
    String? description,
    dynamic thumbData,
    dynamic imageData,
    Uri? imageUri,
  }) =>
      Future.value();

  @override
  Future<void> shareFile({
    required int scene,
    String? title,
    String? description,
    dynamic thumbData,
    dynamic fileData,
    Uri? fileUri,
    String? fileExtension,
  }) =>
      Future.value();

  @override
  Future<void> shareEmoji({
    required int scene,
    String? title,
    String? description,
    required dynamic thumbData,
    dynamic emojiData,
    Uri? emojiUri,
  }) =>
      Future.value();

  @override
  Future<void> shareMediaMusic({
    required int scene,
    String? title,
    String? description,
    dynamic thumbData,
    String? musicUrl,
    String? musicDataUrl,
    String? musicLowBandUrl,
    String? musicLowBandDataUrl,
  }) =>
      Future.value();

  @override
  Future<void> shareVideo({
    required int scene,
    String? title,
    String? description,
    dynamic thumbData,
    String? videoUrl,
    String? videoLowBandUrl,
  }) =>
      Future.value();

  @override
  Future<void> shareWebpage({
    required int scene,
    String? title,
    String? description,
    dynamic thumbData,
    required String webpageUrl,
  }) =>
      Future.value();

  @override
  Future<void> shareMiniProgram({
    required int scene,
    String? title,
    String? description,
    dynamic thumbData,
    required String webpageUrl,
    required String userName,
    String? path,
    dynamic hdImageData,
    bool withShareTicket = false,
    int type = 0,
    bool disableForward = false,
  }) =>
      Future.value();

  @override
  Future<void> subscribeMsg({
    required int scene,
    required String templateId,
    String? reserved,
  }) =>
      Future.value();

  @override
  WechatLaunchMiniProgramResp? takePendingLaunchMiniProgramResp() => null;

  @override
  Future<void> launchMiniProgram({
    required String userName,
    String? path,
    int type = 0,
  }) =>
      Future.value();

  @override
  Future<void> openCustomerServiceChat({
    required String corpId,
    required String url,
  }) =>
      Future.value();

  @override
  Future<void> openBusinessView({
    required String businessType,
    String? query,
    String? extInfo,
  }) =>
      Future.value();

  @override
  Future<void> openBusinessWebview({
    required int businessType,
    Map<String, dynamic>? resultInfo,
  }) =>
      Future.value();

  @override
  Future<void> pay({
    required String appId,
    required String partnerId,
    required String prepayId,
    required String package,
    required String nonceStr,
    required String timeStamp,
    required String sign,
  }) =>
      Future.value();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final WechatBridgePlatform initialPlatform = WechatBridgePlatform.instance;

  test('$MethodChannelWechatBridge is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelWechatBridge>());
  });

  test('platform can be overridden', () async {
    final mock = MockWechatBridgePlatform();
    WechatBridgePlatform.instance = mock;

    expect(await WechatBridgePlatform.instance.isInstalled(), true);
    expect(await WechatBridgePlatform.instance.isSupportApi(), true);

    WechatBridgePlatform.instance = initialPlatform;
  });
}
