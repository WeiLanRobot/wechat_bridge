import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'constant.dart';
import 'model/qrauth.dart';
import 'model/req.dart';
import 'model/resp.dart';
import 'wechat_bridge_platform_interface.dart';

/// MethodChannel 实现
class MethodChannelWechatBridge extends WechatBridgePlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('wechat_bridge')
    ..setMethodCallHandler(_handleMethod);

  static final _reqStreamController = StreamController<WechatReq>.broadcast();
  static final _respStreamController = StreamController<WechatResp>.broadcast();
  static final _qrauthRespStreamController =
      StreamController<WechatQrauthResp>.broadcast();

  static WechatLaunchMiniProgramResp? _pendingLaunchMiniProgramResp;

  static Future<dynamic> _handleMethod(MethodCall call) async {
    if (call.method == 'onAuthQrcodeScanned') {
      _qrauthRespStreamController.add(const WechatQrcodeScannedResp());
      return;
    }

    final args = call.arguments;
    final data = args is Map ? Map<String, dynamic>.from(args) : <String, dynamic>{};

    switch (call.method) {
      case 'onLaunchFromWXReq':
        _reqStreamController.add(WechatLaunchFromWXReq.fromJson(data));
        break;
      case 'onShowMessageFromWXReq':
        _reqStreamController.add(WechatShowMessageFromWXReq.fromJson(data));
        break;
      case 'onAuthResp':
        _respStreamController.add(WechatAuthResp.fromJson(data));
        break;
      case 'onOpenUrlResp':
        _respStreamController.add(WechatOpenUrlResp.fromJson(data));
        break;
      case 'onShareMsgResp':
        _respStreamController.add(WechatShareMsgResp.fromJson(data));
        break;
      case 'onSubscribeMsgResp':
        _respStreamController.add(WechatSubscribeMsgResp.fromJson(data));
        break;
      case 'onLaunchMiniProgramResp': {
        final resp = WechatLaunchMiniProgramResp.fromJson(data);
        _pendingLaunchMiniProgramResp = resp;
        _respStreamController.add(resp);
        break;
      }
      case 'onOpenCustomerServiceChatResp':
        _respStreamController
            .add(WechatOpenCustomerServiceChatResp.fromJson(data));
        break;
      case 'onOpenBusinessViewResp':
        _respStreamController.add(WechatOpenBusinessViewResp.fromJson(data));
        break;
      case 'onOpenBusinessWebviewResp':
        _respStreamController.add(WechatOpenBusinessWebviewResp.fromJson(data));
        break;
      case 'onPayResp':
        _respStreamController.add(WechatPayResp.fromJson(data));
        break;
      case 'onAuthGotQrcode':
        _qrauthRespStreamController.add(WechatGotQrcodeResp.fromJson(data));
        break;
      case 'onAuthFinish':
        _qrauthRespStreamController.add(WechatFinishResp.fromJson(data));
        break;
    }
  }

  @override
  Future<void> registerApp({
    required String appId,
    required String? universalLink,
  }) async {
    assert(!Platform.isIOS || (universalLink?.isNotEmpty ?? false));
    await methodChannel.invokeMethod('registerApp', {
      'appId': appId,
      'universalLink': universalLink,
    });
  }

  @override
  Stream<WechatReq> reqStream() => _reqStreamController.stream;

  @override
  Stream<WechatResp> respStream() => _respStreamController.stream;

  @override
  Stream<WechatQrauthResp> qrauthRespStream() =>
      _qrauthRespStreamController.stream;

  @override
  Future<void> handleInitialWXReq() =>
      methodChannel.invokeMethod('handleInitialWXReq');

  @override
  Future<bool> isInstalled() async =>
      await methodChannel.invokeMethod<bool>('isInstalled') ?? false;

  @override
  Future<bool> isSupportApi() async =>
      await methodChannel.invokeMethod<bool>('isSupportApi') ?? false;

  @override
  Future<bool> isSupportStateApi() async =>
      await methodChannel.invokeMethod<bool>('isSupportStateApi') ?? false;

  @override
  Future<bool> openWechat() async =>
      await methodChannel.invokeMethod<bool>('openWechat') ?? false;

  @override
  Future<void> auth({
    required List<String> scope,
    String? state,
    int type = WechatAuthType.kNormal,
  }) async {
    assert(
      (!Platform.isIOS && type == WechatAuthType.kNormal) ||
          (Platform.isIOS &&
              [WechatAuthType.kNormal, WechatAuthType.kWeb].contains(type)),
    );
    await methodChannel.invokeMethod('auth', {
      'scope': scope.join(','),
      if (state != null) 'state': state,
      'type': type,
    });
  }

  @override
  Future<void> startQrauth({
    required String appId,
    required List<String> scope,
    required String noncestr,
    required String ticket,
  }) async {
    final timestamp = '${DateTime.now().millisecondsSinceEpoch}';
    final content =
        'appid=$appId&noncestr=$noncestr&sdk_ticket=$ticket&timestamp=$timestamp';
    final signature = hex.encode(
      sha1.convert(utf8.encode(content)).bytes,
    );
    await methodChannel.invokeMethod('startQrauth', {
      'appId': appId,
      'scope': scope.join(','),
      'noncestr': noncestr,
      'timestamp': timestamp,
      'signature': signature,
    });
  }

  @override
  Future<void> stopQrauth() => methodChannel.invokeMethod('stopQrauth');

  @override
  Future<void> openUrl({required String url}) async {
    assert(url.length <= 10 * 1024);
    await methodChannel.invokeMethod('openUrl', {'url': url});
  }

  @override
  Future<void> openRankList() =>
      methodChannel.invokeMethod('openRankList');

  @override
  Future<void> shareText({
    required int scene,
    required String text,
  }) async {
    assert(text.length <= 10 * 1024);
    await methodChannel.invokeMethod('shareText', {
      'scene': scene,
      'text': text,
    });
  }

  @override
  Future<void> shareImage({
    required int scene,
    String? title,
    String? description,
    Uint8List? thumbData,
    Uint8List? imageData,
    Uri? imageUri,
  }) async {
    assert(title == null || title.length <= 512);
    assert(description == null || description.length <= 1024);
    assert(thumbData == null || thumbData.lengthInBytes <= 32 * 1024);
    await methodChannel.invokeMethod('shareImage', {
      'scene': scene,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (thumbData != null) 'thumbData': thumbData,
      if (imageData != null) 'imageData': imageData,
      if (imageUri != null) 'imageUri': imageUri.toString(),
    });
  }

  @override
  Future<void> shareFile({
    required int scene,
    String? title,
    String? description,
    Uint8List? thumbData,
    Uint8List? fileData,
    Uri? fileUri,
    String? fileExtension,
  }) async {
    assert(title == null || title.length <= 512);
    assert(description == null || description.length <= 1024);
    assert(thumbData == null || thumbData.lengthInBytes <= 32 * 1024);
    await methodChannel.invokeMethod('shareFile', {
      'scene': scene,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (thumbData != null) 'thumbData': thumbData,
      if (fileData != null) 'fileData': fileData,
      if (fileUri != null) 'fileUri': fileUri.toString(),
      if (fileExtension != null) 'fileExtension': fileExtension,
    });
  }

  @override
  Future<void> shareEmoji({
    required int scene,
    String? title,
    String? description,
    required Uint8List thumbData,
    Uint8List? emojiData,
    Uri? emojiUri,
  }) async {
    assert(title == null || title.length <= 512);
    assert(description == null || description.length <= 1024);
    assert(thumbData.lengthInBytes <= 32 * 1024);
    await methodChannel.invokeMethod('shareEmoji', {
      'scene': scene,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      'thumbData': thumbData,
      if (emojiData != null) 'emojiData': emojiData,
      if (emojiUri != null) 'emojiUri': emojiUri.toString(),
    });
  }

  @override
  Future<void> shareMediaMusic({
    required int scene,
    String? title,
    String? description,
    Uint8List? thumbData,
    String? musicUrl,
    String? musicDataUrl,
    String? musicLowBandUrl,
    String? musicLowBandDataUrl,
  }) async {
    assert(title == null || title.length <= 512);
    assert(description == null || description.length <= 1024);
    assert(thumbData == null || thumbData.lengthInBytes <= 32 * 1024);
    await methodChannel.invokeMethod('shareMusic', {
      'scene': scene,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (thumbData != null) 'thumbData': thumbData,
      if (musicUrl != null) 'musicUrl': musicUrl,
      if (musicDataUrl != null) 'musicDataUrl': musicDataUrl,
      if (musicLowBandUrl != null) 'musicLowBandUrl': musicLowBandUrl,
      if (musicLowBandDataUrl != null)
        'musicLowBandDataUrl': musicLowBandDataUrl,
    });
  }

  @override
  Future<void> shareVideo({
    required int scene,
    String? title,
    String? description,
    Uint8List? thumbData,
    String? videoUrl,
    String? videoLowBandUrl,
  }) async {
    assert(title == null || title.length <= 512);
    assert(description == null || description.length <= 1024);
    assert(thumbData == null || thumbData.lengthInBytes <= 32 * 1024);
    await methodChannel.invokeMethod('shareVideo', {
      'scene': scene,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (thumbData != null) 'thumbData': thumbData,
      if (videoUrl != null) 'videoUrl': videoUrl,
      if (videoLowBandUrl != null) 'videoLowBandUrl': videoLowBandUrl,
    });
  }

  @override
  Future<void> shareWebpage({
    required int scene,
    String? title,
    String? description,
    Uint8List? thumbData,
    required String webpageUrl,
  }) async {
    assert(title == null || title.length <= 512);
    assert(description == null || description.length <= 1024);
    assert(thumbData == null || thumbData.lengthInBytes <= 32 * 1024);
    assert(webpageUrl.length <= 10 * 1024);
    await methodChannel.invokeMethod('shareWebpage', {
      'scene': scene,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (thumbData != null) 'thumbData': thumbData,
      'webpageUrl': webpageUrl,
    });
  }

  @override
  Future<void> shareMiniProgram({
    required int scene,
    String? title,
    String? description,
    Uint8List? thumbData,
    required String webpageUrl,
    required String userName,
    String? path,
    Uint8List? hdImageData,
    bool withShareTicket = false,
    int type = WechatMiniProgram.kRelease,
    bool disableForward = false,
  }) async {
    assert(scene == WechatScene.kSession);
    assert(title == null || title.length <= 512);
    assert(description == null || description.length <= 1024);
    assert(thumbData == null || thumbData.lengthInBytes <= 32 * 1024);
    assert(hdImageData == null || hdImageData.lengthInBytes <= 128 * 1024);
    await methodChannel.invokeMethod('shareMiniProgram', {
      'scene': scene,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (thumbData != null) 'thumbData': thumbData,
      'webpageUrl': webpageUrl,
      'username': userName,
      if (path != null) 'path': path,
      if (hdImageData != null) 'hdImageData': hdImageData,
      'withShareTicket': withShareTicket,
      'type': type,
      'disableForward': disableForward,
    });
  }

  @override
  Future<void> subscribeMsg({
    required int scene,
    required String templateId,
    String? reserved,
  }) async {
    assert(templateId.length <= 1024);
    assert(reserved == null || reserved.length <= 1024);
    await methodChannel.invokeMethod('subscribeMsg', {
      'scene': scene,
      'templateId': templateId,
      if (reserved != null) 'reserved': reserved,
    });
  }

  @override
  WechatLaunchMiniProgramResp? takePendingLaunchMiniProgramResp() {
    final pending = _pendingLaunchMiniProgramResp;
    _pendingLaunchMiniProgramResp = null;
    return pending;
  }

  @override
  Future<void> launchMiniProgram({
    required String userName,
    String? path,
    int type = WechatMiniProgram.kRelease,
  }) async {
    await methodChannel.invokeMethod('launchMiniProgram', {
      'username': userName,
      if (path != null) 'path': path,
      'type': type,
    });
  }

  @override
  Future<void> openCustomerServiceChat({
    required String corpId,
    required String url,
  }) async {
    await methodChannel.invokeMethod('openCustomerServiceChat', {
      'corpId': corpId,
      'url': url,
    });
  }

  @override
  Future<void> openBusinessView({
    required String businessType,
    String? query,
    String? extInfo,
  }) async {
    await methodChannel.invokeMethod('openBusinessView', {
      'businessType': businessType,
      if (query != null) 'query': query,
      if (extInfo != null) 'extInfo': extInfo,
    });
  }

  @override
  Future<void> openBusinessWebview({
    required int businessType,
    Map<String, dynamic>? resultInfo,
  }) async {
    await methodChannel.invokeMethod('openBusinessWebview', {
      'businessType': businessType,
      if (resultInfo != null) 'queryInfo': resultInfo,
    });
  }

  @override
  Future<void> pay({
    required String appId,
    required String partnerId,
    required String prepayId,
    required String package,
    required String nonceStr,
    required String timeStamp,
    required String sign,
  }) async {
    await methodChannel.invokeMethod('pay', {
      'appId': appId,
      'partnerId': partnerId,
      'prepayId': prepayId,
      'noncestr': nonceStr,
      'timestamp': timeStamp,
      'package': package,
      'sign': sign,
    });
  }
}
