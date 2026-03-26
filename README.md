# wechat_bridge

Flutter 版微信登录/分享/支付 SDK。API 与 [wechat_kit](https://pub.dev/packages/wechat_kit) 兼容，便于迁移。使用 Kotlin/Swift 实现，采用较新的微信 SDK。

## 功能特性

- ✅ 微信授权登录
- ✅ 分享（文本、图片、网页、小程序等）
- ✅ 微信支付
- ✅ 打开小程序
- ✅ 一次性订阅消息
- ✅ 扫码登录（Android）

## 安装

```yaml
dependencies:
  wechat_bridge: ^1.0.1
```

## 配置

### Android

- 在 [微信开放平台](https://open.weixin.qq.com/) 创建应用并获取 AppID
- 应用签名需与开放平台配置一致

### iOS

1. **在 Podfile 中指定微信 SDK 的 git 源**

   在 `ios/Podfile` 的 `target 'Runner'` 里、`flutter_install_all_ios_pods` 之前添加：

   ```ruby
   pod 'WechatOpenSDK-Full', :git => 'https://github.com/liujunliuhong/WechatOpenSDK.git', :tag => '1.9.2-0'
   ```

   然后执行 `cd ios && pod install`。

2. 配置 Universal Links，详见 [微信 iOS 接入指南](https://developers.weixin.qq.com/doc/oplatform/Mobile_App/Access_Guide/iOS.html)
3. 在 `Info.plist` 添加 URL Scheme（微信 AppID）

## 使用示例

```dart
import 'package:wechat_bridge/wechat_bridge.dart';

// 注册
await WechatBridgePlatform.instance.registerApp(
  appId: 'your_app_id',
  universalLink: 'https://your-domain.com/wechat/',
);

// 监听回调
WechatBridgePlatform.instance.respStream().listen((resp) {
  if (resp is WechatAuthResp && resp.isSuccessful) {
    // 授权成功，使用 resp.code 换取 access_token
  }
  if (resp is WechatShareMsgResp && resp.isSuccessful) {
    // 分享成功
  }
  if (resp is WechatPayResp && resp.isSuccessful) {
    // 支付成功
  }
  if (resp is WechatLaunchMiniProgramResp && resp.isSuccessful) {
    // 小程序返回，使用 resp.extMsg 处理
  }
});

// App 恢复后取回缓存的小程序回调（可选，用于 respStream 监听未就绪的场景）
final pending = WechatBridgePlatform.instance.takePendingLaunchMiniProgramResp();
if (pending != null && pending.isSuccessful) {
  // 处理 pending.extMsg
}

// 授权登录
await WechatBridgePlatform.instance.auth(
  scope: [WechatScope.kSNSApiUserInfo],
);

// 分享网页
await WechatBridgePlatform.instance.shareWebpage(
  scene: WechatScene.kSession,
  title: '标题',
  description: '描述',
  webpageUrl: 'https://example.com',
);
```

## License

MIT
