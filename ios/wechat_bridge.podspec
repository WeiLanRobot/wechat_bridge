#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint wechat_bridge.podspec` to validate before publishing.
#
# iOS 需要配置 Universal Links，请在应用 pubspec.yaml 中添加：
# wechat_bridge:
#   app_id: your_wechat_app_id
#   universal_link: https://your-domain.com/wechat/
#
Pod::Spec.new do |s|
  s.name             = 'wechat_bridge'
  s.version          = '1.2.0'
  s.summary          = 'Flutter 微信登录/分享/支付 SDK'
  s.description      = <<-DESC
Flutter 版微信登录/分享/支付 SDK，API 与 wechat_kit 兼容。
使用 Kotlin/Swift 实现，采用较新的微信 SDK 2.0.5。
                       DESC
  s.homepage         = 'https://github.com/WeiLanRobot/wechat_bridge'
  s.license          = { :file => '../LICENSE' }
  s.author           = 'wechat_bridge authors'
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'WechatOpenSDK-XCFramework', '2.0.5'
  s.platform = :ios, '13.0'
  s.static_framework = true

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
