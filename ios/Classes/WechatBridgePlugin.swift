import Flutter
import UIKit
import WechatOpenSDK

public class WechatBridgePlugin: NSObject, FlutterPlugin, FlutterApplicationLifeCycleDelegate {
    private var channel: FlutterMethodChannel?
    private var isRunning = false
    private var handleInitialWXReqFlag = false
    private var initialWXReqRunnable: (() -> Void)?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "wechat_bridge", binaryMessenger: registrar.messenger())
        let instance = WechatBridgePlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "registerApp":
            registerApp(call: call, result: result)
        case "handleInitialWXReq":
            handleInitialWXReq(call: call, result: result)
        case "isInstalled":
            result(WXApi.isWXAppInstalled())
        case "isSupportApi":
            result(WXApi.isWXAppSupport())
        case "isSupportStateApi":
            result(WXApi.isWXAppSupportStateAPI())
        case "openWechat":
            result(WXApi.openWXApp())
        case "auth":
            handleAuth(call: call, result: result)
        case "startQrauth", "stopQrauth":
            handleQRAuth(call: call, result: result)
        case "openUrl":
            handleOpenUrl(call: call, result: result)
        case "openRankList":
            handleOpenRankList(call: call, result: result)
        case "shareText":
            handleShareText(call: call, result: result)
        case "shareImage", "shareFile", "shareEmoji", "shareMusic", "shareVideo",
             "shareWebpage", "shareMiniProgram":
            handleShareMedia(call: call, result: result)
        case "subscribeMsg":
            handleSubscribeMsg(call: call, result: result)
        case "launchMiniProgram":
            handleLaunchMiniProgram(call: call, result: result)
        case "openCustomerServiceChat":
            handleOpenCustomerServiceChat(call: call, result: result)
        case "openBusinessView":
            handleOpenBusinessView(call: call, result: result)
        case "openBusinessWebview":
            handleOpenBusinessWebview(call: call, result: result)
        case "pay":
            handlePay(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func registerApp(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let appId = args["appId"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "appId is required", details: nil))
            return
        }
        let universalLink = args["universalLink"] as? String
        WXApi.registerApp(appId, universalLink: universalLink ?? "")
        isRunning = true
        result(nil)
    }

    private func handleInitialWXReq(call: FlutterMethodCall, result: @escaping FlutterResult) {
        if !handleInitialWXReqFlag {
            handleInitialWXReqFlag = true
            initialWXReqRunnable?()
            initialWXReqRunnable = nil
        }
        // 幂等：第二次及后续调用直接返回成功，避免 PlatformException(FAILED)
        result(nil)
    }

    private func handleAuth(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let scope = args["scope"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "scope is required", details: nil))
            return
        }
        let req = SendAuthReq()
        req.scope = scope
        req.state = args["state"] as? String ?? ""
        let type = args["type"] as? Int ?? 0
        if type == 0 {
            WXApi.send(req) { _ in }
        } else if type == 1 {
            var vc: UIViewController?
            if #available(iOS 13.0, *) {
                vc = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .first { $0.isKeyWindow }?.rootViewController
            } else {
                vc = UIApplication.shared.keyWindow?.rootViewController
            }
            if let vc = vc {
                WXApi.sendAuthReq(req, viewController: vc, delegate: self) { _ in }
            } else {
                // Flutter 场景下可能拿不到 VC，回退到普通方式
                WXApi.send(req) { _ in }
            }
        }
        result(nil)
    }

    private func handleQRAuth(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // 扫码登录需要 WechatAuthSDK，WechatOpenSDK-Full 可能包含
        result(FlutterError(code: "UNIMPLEMENTED", message: "扫码登录请使用 wechat_kit", details: nil))
    }

    private func handleOpenUrl(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let url = args["url"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "url is required", details: nil))
            return
        }
        let req = OpenWebviewReq()
        req.url = url
        WXApi.send(req) { _ in }
        result(nil)
    }

    private func handleOpenRankList(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let req = OpenRankListReq()
        WXApi.send(req) { _ in }
        result(nil)
    }

    private func handleShareText(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let text = args["text"] as? String,
              let scene = args["scene"] as? Int else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "text and scene required", details: nil))
            return
        }


        let req = SendMessageToWXReq()
        req.bText = true
        req.text = text
        req.scene = Int32(scene)
        WXApi.send(req) { _ in }
        result(nil)
    }

    private func handleShareMedia(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let scene = args["scene"] as? Int else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "scene required", details: nil))
            return
        }
        let req = SendMessageToWXReq()
        req.bText = false
        req.scene = Int32(scene)
        let message = WXMediaMessage()
        message.title = args["title"] as? String ?? ""
        message.description = args["description"] as? String ?? ""
        if let thumbData = args["thumbData"] as? FlutterStandardTypedData {
            message.thumbData = thumbData.data
        }

        switch call.method {
        case "shareImage":
            let obj = WXImageObject()
            if let imageData = args["imageData"] as? FlutterStandardTypedData {
                obj.imageData = imageData.data
            } else if let imageUri = args["imageUri"] as? String,
                      let url = URL(string: imageUri),
                      let data = try? Data(contentsOf: url) {
                obj.imageData = data
            }
            message.mediaObject = obj
        case "shareFile":
            let obj = WXFileObject()
            if let fileData = args["fileData"] as? FlutterStandardTypedData {
                obj.fileData = fileData.data
            } else if let fileUri = args["fileUri"] as? String,
                      let url = URL(string: fileUri),
                      let data = try? Data(contentsOf: url) {
                obj.fileData = data
            }
            obj.fileExtension = args["fileExtension"] as? String ?? ""
            message.mediaObject = obj
        case "shareEmoji":
            let obj = WXEmoticonObject()
            if let emojiData = args["emojiData"] as? FlutterStandardTypedData {
                obj.emoticonData = emojiData.data
            } else if let emojiUri = args["emojiUri"] as? String,
                      let url = URL(string: emojiUri),
                      let data = try? Data(contentsOf: url) {
                obj.emoticonData = data
            }
            message.mediaObject = obj
        case "shareMusic":
            let obj = WXMusicObject()
            obj.musicUrl = args["musicUrl"] as? String ?? ""
            obj.musicDataUrl = args["musicDataUrl"] as? String ?? ""
            obj.musicLowBandUrl = args["musicLowBandUrl"] as? String ?? ""
            obj.musicLowBandDataUrl = args["musicLowBandDataUrl"] as? String ?? ""
            message.mediaObject = obj
        case "shareVideo":
            let obj = WXVideoObject()
            obj.videoUrl = args["videoUrl"] as? String ?? ""
            obj.videoLowBandUrl = args["videoLowBandUrl"] as? String ?? ""
            message.mediaObject = obj
        case "shareWebpage":
            let obj = WXWebpageObject()
            obj.webpageUrl = args["webpageUrl"] as? String ?? ""
            message.mediaObject = obj
        case "shareMiniProgram":
            let obj = WXMiniProgramObject()
            obj.webpageUrl = args["webpageUrl"] as? String ?? ""
            obj.userName = args["username"] as? String ?? ""
            obj.path = args["path"] as? String
            if let hdImageData = args["hdImageData"] as? FlutterStandardTypedData {
                message.thumbData = hdImageData.data
            }
            obj.withShareTicket = args["withShareTicket"] as? Bool ?? false
            obj.miniProgramType = WXMiniProgramType(rawValue: UInt(args["type"] as? Int ?? 0)) ?? .release
            obj.disableForward = args["disableForward"] as? Bool ?? false
            message.mediaObject = obj
        default:
            break
        }
        req.message = message
        WXApi.send(req) { _ in }
        result(nil)
    }

    private func handleSubscribeMsg(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let scene = args["scene"] as? Int,
              let templateId = args["templateId"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "scene and templateId required", details: nil))
            return
        }
        let req = WXSubscribeMsgReq()
        req.scene = UInt32(scene)
        req.templateId = templateId
        req.reserved = args["reserved"] as? String
        WXApi.send(req) { _ in }
        result(nil)
    }

    private func handleLaunchMiniProgram(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let userName = args["username"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "username required", details: nil))
            return
        }
        let req = WXLaunchMiniProgramReq()
        req.userName = userName
        req.path = args["path"] as? String
        req.miniProgramType = WXMiniProgramType(rawValue: UInt(args["type"] as? Int ?? 0)) ?? .release
        WXApi.send(req) { _ in }
        result(nil)
    }

    private func handleOpenCustomerServiceChat(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let corpId = args["corpId"] as? String,
              let url = args["url"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "corpId and url required", details: nil))
            return
        }
        let req = WXOpenCustomerServiceReq()
        req.corpid = corpId
        req.url = url
        WXApi.send(req) { _ in }
        result(nil)
    }

    private func handleOpenBusinessView(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let businessType = args["businessType"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "businessType required", details: nil))
            return
        }
        let req = WXOpenBusinessViewReq()
        req.businessType = businessType
        req.query = args["query"] as? String
        req.extInfo = args["extInfo"] as? String
        WXApi.send(req) { _ in }
        result(nil)
    }

    private func handleOpenBusinessWebview(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let businessType = args["businessType"] as? Int else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "businessType required", details: nil))
            return
        }
        let req = WXOpenBusinessWebViewReq()
        req.businessType = UInt32(businessType)
        req.queryInfoDic = args["queryInfo"] as? [AnyHashable: Any]
        WXApi.send(req) { _ in }
        result(nil)
    }

    private func handlePay(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let partnerId = args["partnerId"] as? String,
              let prepayId = args["prepayId"] as? String,
              let nonceStr = args["noncestr"] as? String,
              let timeStamp = args["timestamp"] as? String,
              let package = args["package"] as? String,
              let sign = args["sign"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "pay params required", details: nil))
            return
        }
        let req = PayReq()
        req.partnerId = partnerId
        req.prepayId = prepayId
        req.nonceStr = nonceStr
        req.timeStamp = UInt32(timeStamp) ?? 0
        req.package = package
        req.sign = sign
        WXApi.send(req) { _ in }
        result(nil)
    }

    // MARK: - FlutterApplicationLifeCycleDelegate

    public func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return WXApi.handleOpen(url, delegate: self)
    }

    public func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]) -> Void) -> Bool {
        return WXApi.handleOpenUniversalLink(userActivity, delegate: self)
    }
}

extension WechatBridgePlugin: WXApiDelegate {
    public func onReq(_ req: BaseReq) {
        var dict: [String: Any] = [:]
        if let launchReq = req as? LaunchFromWXReq {
            let msg = launchReq.message
            dict["messageAction"] = msg.messageAction ?? ""
            dict["messageExt"] = msg.messageExt ?? ""
            dict["lang"] = launchReq.lang ?? ""
            dict["country"] = launchReq.country ?? ""
            if isRunning {
                channel?.invokeMethod("onLaunchFromWXReq", arguments: dict)
            } else {
                initialWXReqRunnable = { [weak self] in
                    self?.channel?.invokeMethod("onLaunchFromWXReq", arguments: dict)
                }
            }
        } else if let showReq = req as? ShowMessageFromWXReq {
            let msg = showReq.message
            dict["messageAction"] = msg.messageAction ?? ""
            dict["messageExt"] = msg.messageExt ?? ""
            dict["lang"] = showReq.lang ?? ""
            dict["country"] = showReq.country ?? ""
            if isRunning {
                channel?.invokeMethod("onShowMessageFromWXReq", arguments: dict)
            } else {
                initialWXReqRunnable = { [weak self] in
                    self?.channel?.invokeMethod("onShowMessageFromWXReq", arguments: dict)
                }
            }
        }
    }

    public func onResp(_ resp: BaseResp) {
        var dict: [String: Any] = [
            "errorCode": resp.errCode,
            "errorMsg": resp.errStr ?? ""
        ]
        switch resp {
        case let authResp as SendAuthResp:
            if resp.errCode == 0 {
                dict["code"] = authResp.code ?? ""
                dict["state"] = authResp.state ?? ""
                dict["lang"] = authResp.lang ?? ""
                dict["country"] = authResp.country ?? ""
            }
            channel?.invokeMethod("onAuthResp", arguments: dict)
        case is OpenWebviewResp:
            channel?.invokeMethod("onOpenUrlResp", arguments: dict)
        case is SendMessageToWXResp:
            channel?.invokeMethod("onShareMsgResp", arguments: dict)
        case let subResp as WXSubscribeMsgResp:
            if resp.errCode == 0 {
                dict["openId"] = subResp.openId ?? ""
                dict["templateId"] = subResp.templateId ?? ""
                dict["scene"] = subResp.scene
                dict["action"] = subResp.action ?? ""
                dict["reserved"] = subResp.reserved ?? ""
            }
            channel?.invokeMethod("onSubscribeMsgResp", arguments: dict)
        case let mpResp as WXLaunchMiniProgramResp:
            if resp.errCode == 0 {
                dict["extMsg"] = mpResp.extMsg ?? ""
            }
            channel?.invokeMethod("onLaunchMiniProgramResp", arguments: dict)
        case is WXOpenCustomerServiceResp:
            channel?.invokeMethod("onOpenCustomerServiceChatResp", arguments: dict)
        case let bvResp as WXOpenBusinessViewResp:
            if resp.errCode == 0 {
                dict["businessType"] = bvResp.businessType ?? ""
                dict["extMsg"] = bvResp.extMsg ?? ""
            }
            channel?.invokeMethod("onOpenBusinessViewResp", arguments: dict)
        case let bwResp as WXOpenBusinessWebViewResp:
            if resp.errCode == 0 {
                dict["businessType"] = bwResp.businessType
                dict["resultInfo"] = bwResp.result ?? ""
            }
            channel?.invokeMethod("onOpenBusinessWebviewResp", arguments: dict)
        case let payResp as PayResp:
            if resp.errCode == 0 {
                dict["returnKey"] = payResp.returnKey ?? ""
            }
            channel?.invokeMethod("onPayResp", arguments: dict)
        default:
            break
        }
    }
}
