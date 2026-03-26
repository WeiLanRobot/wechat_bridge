import 'dart:convert';

/// 微信请求基类
abstract class WechatReq {
  const WechatReq();

  Map<String, dynamic> toJson();

  @override
  String toString() =>
      const JsonEncoder.withIndent(' ').convert(toJson());
}

/// 从微信冷启动请求
class WechatLaunchFromWXReq extends WechatReq {
  const WechatLaunchFromWXReq({
    this.messageAction,
    this.messageExt,
    required this.lang,
    required this.country,
  });

  factory WechatLaunchFromWXReq.fromJson(Map<String, dynamic> json) =>
      WechatLaunchFromWXReq(
        messageAction: json['messageAction'] as String?,
        messageExt: json['messageExt'] as String?,
        lang: json['lang'] as String,
        country: json['country'] as String,
      );

  final String? messageAction;
  final String? messageExt;
  final String lang;
  final String country;

  @override
  Map<String, dynamic> toJson() => {
        if (messageAction != null) 'messageAction': messageAction,
        if (messageExt != null) 'messageExt': messageExt,
        'lang': lang,
        'country': country,
      };
}

/// 从微信展示消息请求
class WechatShowMessageFromWXReq extends WechatReq {
  const WechatShowMessageFromWXReq({
    this.messageAction,
    this.messageExt,
    required this.lang,
    required this.country,
  });

  factory WechatShowMessageFromWXReq.fromJson(Map<String, dynamic> json) =>
      WechatShowMessageFromWXReq(
        messageAction: json['messageAction'] as String?,
        messageExt: json['messageExt'] as String?,
        lang: json['lang'] as String,
        country: json['country'] as String,
      );

  final String? messageAction;
  final String? messageExt;
  final String lang;
  final String country;

  @override
  Map<String, dynamic> toJson() => {
        if (messageAction != null) 'messageAction': messageAction,
        if (messageExt != null) 'messageExt': messageExt,
        'lang': lang,
        'country': country,
      };
}
