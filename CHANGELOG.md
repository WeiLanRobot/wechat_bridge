## 1.1.1

* 移除冗余文档注释

## 1.1.0

* 修复 iOS 侧 `LaunchFromWXReq.message` 和 `ShowMessageFromWXReq.message` 在新版微信 SDK 下的可选链编译错误（`Cannot use optional chaining on non-optional value`）
* 保持对现有回调字段 `messageAction` 与 `messageExt` 的兼容，不影响上层 API 使用

## 1.0.1

* 新增 `takePendingLaunchMiniProgramResp()`，在 App 从后台恢复时取回缓存的小程序返回回调
* 缓存 `WechatLaunchMiniProgramResp`，解决 respStream 监听器尚未就绪导致回调丢失的问题
* 向后兼容，不影响现有 respStream 用法

## 1.0.0

* podspec 添加 `static_framework = true`，解决 CocoaPods 静态库 transitive dependencies 错误
* Podfile 指定 `platform :ios, '12.0'`
* 修复 iOS 12 兼容：`connectedScenes`/`UIWindowScene` 仅在 iOS 13+ 使用，iOS 12 回退到 `keyWindow`
* 修复 `WXMiniProgramType` rawValue 类型转换（Int → UInt）
* 修复 Dart `dangling_library_doc_comments` 告警

## 0.6.0

* 适配新版微信 iOS SDK API：`isWXAppSupportApi` → `isWXAppSupport`，`miniprogramType` → `miniProgramType`，`corpId` → `corpid` 等
* 修复 iOS `PayReq` 无 `appId` 字段导致的编译错误
* 修复 `WXMediaMessage`、`WXMiniProgramObject` 等可选类型与类型转换问题

## 0.5.0

* Podfile 中指定微信 SDK 的 git 源（WechatOpenSDK-Full）

## 0.4.0

* 修复 Android `handleShareMediaCall` 缺少 `req.message = message` 导致分享失败
* 修复 iOS `handlePay` 缺少 `req.appId` 赋值

## 0.3.0

* Android 包名改为 `com.weilan.wechat_bridge`

## 0.2.0

* 修复 AndroidManifest：将 `<activity>` 和 `<provider>` 移入 `<application>` 内，满足 AAPT2 构建要求

## 0.1.0

* 初始版本
* 微信授权登录
* 分享（文本、图片、网页、小程序等）
* 微信支付
* 打开小程序
* 一次性订阅消息
* 扫码登录（Android）
* API 与 wechat_kit 兼容
