import 'dart:convert';
import 'dart:typed_data';

/// 扫码登录响应基类
abstract class WechatQrauthResp {
  const WechatQrauthResp();

  Map<String, dynamic> toJson();

  @override
  String toString() =>
      const JsonEncoder.withIndent(' ').convert(toJson());
}

/// 获取二维码响应
class WechatGotQrcodeResp extends WechatQrauthResp {
  const WechatGotQrcodeResp({
    required this.imageData,
  });

  factory WechatGotQrcodeResp.fromJson(Map<String, dynamic> json) {
    final data = json['imageData'];
    if (data is Uint8List) {
      return WechatGotQrcodeResp(imageData: data);
    }
    if (data is List) {
      return WechatGotQrcodeResp(
        imageData: Uint8List.fromList(
          data.map((e) => (e as num).toInt()).toList(),
        ),
      );
    }
    throw ArgumentError('Invalid imageData type');
  }

  final Uint8List imageData;

  @override
  Map<String, dynamic> toJson() => {'imageData': imageData};
}

/// 二维码已扫描响应
class WechatQrcodeScannedResp extends WechatQrauthResp {
  const WechatQrcodeScannedResp();

  factory WechatQrcodeScannedResp.fromJson(Map<String, dynamic> json) =>
      const WechatQrcodeScannedResp();

  @override
  Map<String, dynamic> toJson() => {};
}

/// 扫码登录完成响应
class WechatFinishResp extends WechatQrauthResp {
  const WechatFinishResp({
    required this.errorCode,
    this.authCode,
  });

  /// Auth 成功
  static const int kErrorCodeSuccess = 0;

  /// 普通错误
  static const int kErrorCodeNormal = -1;

  /// 网络错误
  static const int kErrorCodeNetwork = -2;

  /// 获取二维码失败
  static const int kErrorCodeGetQrcodeFailed = -3;

  /// 用户取消授权
  static const int kErrorCodeCancel = -4;

  /// 超时
  static const int kErrorCodeTimeout = -5;

  factory WechatFinishResp.fromJson(Map<String, dynamic> json) =>
      WechatFinishResp(
        errorCode: json['errorCode'] as int? ?? kErrorCodeSuccess,
        authCode: json['authCode'] as String?,
      );

  final int errorCode;
  final String? authCode;

  bool get isSuccessful => errorCode == kErrorCodeSuccess;

  bool get isCancelled => errorCode == kErrorCodeCancel;

  @override
  Map<String, dynamic> toJson() => {
        'errorCode': errorCode,
        if (authCode != null) 'authCode': authCode,
      };
}
