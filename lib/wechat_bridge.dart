/// Flutter 版微信登录/分享/支付 SDK
///
/// API 与 [wechat_kit](https://pub.dev/packages/wechat_kit) 兼容，便于从 wechat_kit 迁移。
/// 使用 Kotlin/Swift 实现，采用较新的微信 SDK 版本。
///
/// 使用示例：
/// ```dart
/// // 注册
/// await WechatBridgePlatform.instance.registerApp(
///   appId: 'your_app_id',
///   universalLink: 'https://your-domain.com/wechat/',
/// );
///
/// // 监听回调
/// WechatBridgePlatform.instance.respStream().listen((resp) {
///   if (resp is WechatAuthResp && resp.isSuccessful) {
///     // 处理授权成功
///   }
/// });
///
/// // 授权登录
/// await WechatBridgePlatform.instance.auth(
///   scope: [WechatScope.kSNSApiUserInfo],
/// );
/// ```
library;

export 'src/constant.dart';
export 'src/model/qrauth.dart';
export 'src/model/req.dart';
export 'src/model/resp.dart';
export 'src/wechat_bridge_method_channel.dart';
export 'src/wechat_bridge_platform_interface.dart';
