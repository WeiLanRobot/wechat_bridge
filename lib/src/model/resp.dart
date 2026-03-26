import 'dart:convert';

/// 微信响应基类
abstract class WechatResp {
  const WechatResp({
    required this.errorCode,
    this.errorMsg,
  });

  /// 成功
  static const int kErrorCodeSuccess = 0;

  /// 普通错误类型
  static const int kErrorCodeCommon = -1;

  /// 用户点击取消并返回
  static const int kErrorCodeUserCancel = -2;

  /// 发送失败
  static const int kErrorCodeSentFail = -3;

  /// 授权失败
  static const int kErrorCodeAuthDeny = -4;

  /// 微信不支持
  static const int kErrorCodeUnsupport = -5;

  /// 错误码
  final int errorCode;

  /// 错误提示字符串
  final String? errorMsg;

  bool get isSuccessful => errorCode == kErrorCodeSuccess;

  bool get isCancelled => errorCode == kErrorCodeUserCancel;

  Map<String, dynamic> toJson();

  @override
  String toString() =>
      const JsonEncoder.withIndent(' ').convert(toJson());
}

/// 授权响应
class WechatAuthResp extends WechatResp {
  const WechatAuthResp({
    required super.errorCode,
    super.errorMsg,
    this.code,
    this.state,
    this.lang,
    this.country,
  });

  factory WechatAuthResp.fromJson(Map<String, dynamic> json) =>
      WechatAuthResp(
        errorCode: json['errorCode'] as int? ?? WechatResp.kErrorCodeSuccess,
        errorMsg: json['errorMsg'] as String?,
        code: json['code'] as String?,
        state: json['state'] as String?,
        lang: json['lang'] as String?,
        country: json['country'] as String?,
      );

  final String? code;
  final String? state;
  final String? lang;
  final String? country;

  @override
  Map<String, dynamic> toJson() => {
        'errorCode': errorCode,
        if (errorMsg != null) 'errorMsg': errorMsg,
        if (code != null) 'code': code,
        if (state != null) 'state': state,
        if (lang != null) 'lang': lang,
        if (country != null) 'country': country,
      };
}

/// 打开链接响应
class WechatOpenUrlResp extends WechatResp {
  const WechatOpenUrlResp({
    required super.errorCode,
    super.errorMsg,
  });

  factory WechatOpenUrlResp.fromJson(Map<String, dynamic> json) =>
      WechatOpenUrlResp(
        errorCode: json['errorCode'] as int? ?? WechatResp.kErrorCodeSuccess,
        errorMsg: json['errorMsg'] as String?,
      );

  @override
  Map<String, dynamic> toJson() => {
        'errorCode': errorCode,
        if (errorMsg != null) 'errorMsg': errorMsg,
      };
}

/// 分享消息响应
class WechatShareMsgResp extends WechatResp {
  const WechatShareMsgResp({
    required super.errorCode,
    super.errorMsg,
  });

  factory WechatShareMsgResp.fromJson(Map<String, dynamic> json) =>
      WechatShareMsgResp(
        errorCode: json['errorCode'] as int? ?? WechatResp.kErrorCodeSuccess,
        errorMsg: json['errorMsg'] as String?,
      );

  @override
  Map<String, dynamic> toJson() => {
        'errorCode': errorCode,
        if (errorMsg != null) 'errorMsg': errorMsg,
      };
}

/// 一次性订阅消息响应
class WechatSubscribeMsgResp extends WechatResp {
  const WechatSubscribeMsgResp({
    required super.errorCode,
    super.errorMsg,
    this.openId,
    this.templateId,
    this.scene,
    this.action,
    this.reserved,
  });

  factory WechatSubscribeMsgResp.fromJson(Map<String, dynamic> json) =>
      WechatSubscribeMsgResp(
        errorCode: json['errorCode'] as int? ?? WechatResp.kErrorCodeSuccess,
        errorMsg: json['errorMsg'] as String?,
        openId: json['openId'] as String?,
        templateId: json['templateId'] as String?,
        scene: json['scene'] as int?,
        action: json['action'] as String?,
        reserved: json['reserved'] as String?,
      );

  final String? openId;
  final String? templateId;
  final int? scene;
  final String? action;
  final String? reserved;

  @override
  Map<String, dynamic> toJson() => {
        'errorCode': errorCode,
        if (errorMsg != null) 'errorMsg': errorMsg,
        if (openId != null) 'openId': openId,
        if (templateId != null) 'templateId': templateId,
        if (scene != null) 'scene': scene,
        if (action != null) 'action': action,
        if (reserved != null) 'reserved': reserved,
      };
}

/// 打开小程序响应
class WechatLaunchMiniProgramResp extends WechatResp {
  const WechatLaunchMiniProgramResp({
    required super.errorCode,
    super.errorMsg,
    this.extMsg,
  });

  factory WechatLaunchMiniProgramResp.fromJson(Map<String, dynamic> json) =>
      WechatLaunchMiniProgramResp(
        errorCode: json['errorCode'] as int? ?? WechatResp.kErrorCodeSuccess,
        errorMsg: json['errorMsg'] as String?,
        extMsg: json['extMsg'] as String?,
      );

  final String? extMsg;

  @override
  Map<String, dynamic> toJson() => {
        'errorCode': errorCode,
        if (errorMsg != null) 'errorMsg': errorMsg,
        if (extMsg != null) 'extMsg': extMsg,
      };
}

/// 打开客服会话响应
class WechatOpenCustomerServiceChatResp extends WechatResp {
  const WechatOpenCustomerServiceChatResp({
    required super.errorCode,
    super.errorMsg,
  });

  factory WechatOpenCustomerServiceChatResp.fromJson(
          Map<String, dynamic> json) =>
      WechatOpenCustomerServiceChatResp(
        errorCode: json['errorCode'] as int? ?? WechatResp.kErrorCodeSuccess,
        errorMsg: json['errorMsg'] as String?,
      );

  @override
  Map<String, dynamic> toJson() => {
        'errorCode': errorCode,
        if (errorMsg != null) 'errorMsg': errorMsg,
      };
}

/// 打开业务视图响应（支付分等）
class WechatOpenBusinessViewResp extends WechatResp {
  const WechatOpenBusinessViewResp({
    required super.errorCode,
    super.errorMsg,
    required this.businessType,
    this.extMsg,
  });

  factory WechatOpenBusinessViewResp.fromJson(Map<String, dynamic> json) =>
      WechatOpenBusinessViewResp(
        errorCode: json['errorCode'] as int? ?? WechatResp.kErrorCodeSuccess,
        errorMsg: json['errorMsg'] as String?,
        businessType: json['businessType'] as String? ?? '',
        extMsg: json['extMsg'] as String?,
      );

  final String businessType;
  final String? extMsg;

  @override
  Map<String, dynamic> toJson() => {
        'errorCode': errorCode,
        if (errorMsg != null) 'errorMsg': errorMsg,
        'businessType': businessType,
        if (extMsg != null) 'extMsg': extMsg,
      };
}

/// 打开业务 Webview 响应
class WechatOpenBusinessWebviewResp extends WechatResp {
  const WechatOpenBusinessWebviewResp({
    required super.errorCode,
    super.errorMsg,
    required this.businessType,
    this.resultInfo,
  });

  factory WechatOpenBusinessWebviewResp.fromJson(Map<String, dynamic> json) =>
      WechatOpenBusinessWebviewResp(
        errorCode: json['errorCode'] as int? ?? WechatResp.kErrorCodeSuccess,
        errorMsg: json['errorMsg'] as String?,
        businessType: json['businessType'] as int? ?? 0,
        resultInfo: json['resultInfo'] as String?,
      );

  final int businessType;
  final String? resultInfo;

  @override
  Map<String, dynamic> toJson() => {
        'errorCode': errorCode,
        if (errorMsg != null) 'errorMsg': errorMsg,
        'businessType': businessType,
        if (resultInfo != null) 'resultInfo': resultInfo,
      };
}

/// 支付响应
class WechatPayResp extends WechatResp {
  const WechatPayResp({
    required super.errorCode,
    super.errorMsg,
    this.returnKey,
  });

  factory WechatPayResp.fromJson(Map<String, dynamic> json) => WechatPayResp(
        errorCode: json['errorCode'] as int? ?? WechatResp.kErrorCodeSuccess,
        errorMsg: json['errorMsg'] as String?,
        returnKey: json['returnKey'] as String?,
      );

  final String? returnKey;

  @override
  Map<String, dynamic> toJson() => {
        'errorCode': errorCode,
        if (errorMsg != null) 'errorMsg': errorMsg,
        if (returnKey != null) 'returnKey': returnKey,
      };
}
