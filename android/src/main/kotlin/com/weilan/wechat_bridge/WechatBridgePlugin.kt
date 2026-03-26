package com.weilan.wechat_bridge

import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ProviderInfo
import android.net.Uri
import android.os.Build
import com.tencent.mm.opensdk.constants.Build as WxBuild
import com.tencent.mm.opensdk.diffdev.DiffDevOAuthFactory
import com.tencent.mm.opensdk.diffdev.IDiffDevOAuth
import com.tencent.mm.opensdk.diffdev.OAuthErrCode
import com.tencent.mm.opensdk.diffdev.OAuthListener
import com.tencent.mm.opensdk.modelbase.BaseResp
import com.tencent.mm.opensdk.modelbiz.OpenRankList
import com.tencent.mm.opensdk.modelbiz.OpenWebview
import com.tencent.mm.opensdk.modelbiz.SubscribeMessage
import com.tencent.mm.opensdk.modelbiz.WXLaunchMiniProgram
import com.tencent.mm.opensdk.modelbiz.WXOpenBusinessView
import com.tencent.mm.opensdk.modelbiz.WXOpenBusinessWebview
import com.tencent.mm.opensdk.modelbiz.WXOpenCustomerServiceChat
import com.tencent.mm.opensdk.modelmsg.LaunchFromWX
import com.tencent.mm.opensdk.modelmsg.SendAuth
import com.tencent.mm.opensdk.modelmsg.SendMessageToWX
import com.tencent.mm.opensdk.modelmsg.ShowMessageFromWX
import com.tencent.mm.opensdk.modelmsg.WXEmojiObject
import com.tencent.mm.opensdk.modelmsg.WXFileObject
import com.tencent.mm.opensdk.modelmsg.WXImageObject
import com.tencent.mm.opensdk.modelmsg.WXMediaMessage
import com.tencent.mm.opensdk.modelmsg.WXMiniProgramObject
import com.tencent.mm.opensdk.modelmsg.WXMusicObject
import com.tencent.mm.opensdk.modelmsg.WXTextObject
import com.tencent.mm.opensdk.modelmsg.WXVideoObject
import com.tencent.mm.opensdk.modelmsg.WXWebpageObject
import com.tencent.mm.opensdk.modelpay.PayReq
import com.tencent.mm.opensdk.modelpay.PayResp
import com.tencent.mm.opensdk.openapi.IWXAPI
import com.tencent.mm.opensdk.openapi.IWXAPIEventHandler
import com.tencent.mm.opensdk.openapi.WXAPIFactory
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.util.concurrent.atomic.AtomicBoolean

class WechatBridgePlugin : FlutterPlugin, ActivityAware, PluginRegistry.NewIntentListener, MethodChannel.MethodCallHandler {

    private var channel: MethodChannel? = null
    private var applicationContext: Context? = null
    private var activityPluginBinding: ActivityPluginBinding? = null

    private val qrauth: IDiffDevOAuth = DiffDevOAuthFactory.getDiffDevOAuth()
    private var iwxapi: IWXAPI? = null
    private val handleInitialWXReqFlag = AtomicBoolean(false)

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "wechat_bridge")
        channel!!.setMethodCallHandler(this)
        applicationContext = binding.applicationContext
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        applicationContext = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityPluginBinding = binding
        activityPluginBinding!!.addOnNewIntentListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        qrauth.removeAllListeners()
        activityPluginBinding = null
    }

    override fun onNewIntent(intent: Intent): Boolean {
        val extra = WechatCallbackActivity.extraCallback(intent)
        if (extra != null) {
            iwxapi?.handleIntent(extra, iwxapiEventHandler)
            return true
        }
        return false
    }

    private val iwxapiEventHandler = object : IWXAPIEventHandler {
        override fun onReq(req: com.tencent.mm.opensdk.modelbase.BaseReq) {
            val map = mutableMapOf<String, Any?>()
            when (req) {
                is LaunchFromWX.Req -> {
                    map["messageAction"] = req.messageAction
                    map["messageExt"] = req.messageExt
                    map["lang"] = req.lang
                    map["country"] = req.country
                    channel?.invokeMethod("onLaunchFromWXReq", map)
                }
                is ShowMessageFromWX.Req -> {
                    map["messageAction"] = req.message.messageAction
                    map["messageExt"] = req.message.messageExt
                    map["lang"] = req.lang
                    map["country"] = req.country
                    channel?.invokeMethod("onShowMessageFromWXReq", map)
                }
            }
        }

        override fun onResp(resp: BaseResp) {
            val map = mutableMapOf<String, Any?>(
                "errorCode" to resp.errCode,
                "errorMsg" to resp.errStr
            )
            when (resp) {
                is SendAuth.Resp -> {
                    if (resp.errCode == BaseResp.ErrCode.ERR_OK) {
                        map["code"] = resp.code
                        map["state"] = resp.state
                        map["lang"] = resp.lang
                        map["country"] = resp.country
                    }
                    channel?.invokeMethod("onAuthResp", map)
                }
                is OpenWebview.Resp -> channel?.invokeMethod("onOpenUrlResp", map)
                is SendMessageToWX.Resp -> channel?.invokeMethod("onShareMsgResp", map)
                is SubscribeMessage.Resp -> {
                    if (resp.errCode == BaseResp.ErrCode.ERR_OK) {
                        map["openId"] = resp.openId
                        map["templateId"] = resp.templateID
                        map["scene"] = resp.scene
                        map["action"] = resp.action
                        map["reserved"] = resp.reserved
                    }
                    channel?.invokeMethod("onSubscribeMsgResp", map)
                }
                is WXLaunchMiniProgram.Resp -> {
                    if (resp.errCode == BaseResp.ErrCode.ERR_OK) {
                        map["extMsg"] = resp.extMsg
                    }
                    channel?.invokeMethod("onLaunchMiniProgramResp", map)
                }
                is WXOpenCustomerServiceChat.Resp ->
                    channel?.invokeMethod("onOpenCustomerServiceChatResp", map)
                is WXOpenBusinessView.Resp -> {
                    if (resp.errCode == BaseResp.ErrCode.ERR_OK) {
                        map["businessType"] = resp.businessType
                        map["extMsg"] = resp.extMsg
                    }
                    channel?.invokeMethod("onOpenBusinessViewResp", map)
                }
                is WXOpenBusinessWebview.Resp -> {
                    if (resp.errCode == BaseResp.ErrCode.ERR_OK) {
                        map["businessType"] = resp.businessType
                        map["resultInfo"] = resp.resultInfo
                    }
                    channel?.invokeMethod("onOpenBusinessWebviewResp", map)
                }
                is PayResp -> {
                    if (resp.errCode == BaseResp.ErrCode.ERR_OK) {
                        map["returnKey"] = resp.returnKey
                    }
                    channel?.invokeMethod("onPayResp", map)
                }
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "registerApp" -> registerApp(call, result)
            "handleInitialWXReq" -> handleInitialWXReq(call, result)
            "isInstalled" -> result.success(iwxapi != null && iwxapi!!.isWXAppInstalled)
            "isSupportApi" -> result.success(
                iwxapi != null && iwxapi!!.wxAppSupportAPI >= WxBuild.OPENID_SUPPORTED_SDK_INT
            )
            "isSupportStateApi" -> result.success(
                iwxapi != null && iwxapi!!.wxAppSupportAPI >= WxBuild.SUPPORTED_SEND_TO_STATUS
            )
            "openWechat" -> result.success(iwxapi?.openWXApp() ?: false)
            "auth" -> handleAuthCall(call, result)
            "startQrauth", "stopQrauth" -> handleQRAuthCall(call, result)
            "openUrl" -> handleOpenUrlCall(call, result)
            "openRankList" -> handleOpenRankListCall(call, result)
            "shareText" -> handleShareTextCall(call, result)
            "shareImage", "shareFile", "shareEmoji", "shareMusic", "shareVideo",
            "shareWebpage", "shareMiniProgram" -> handleShareMediaCall(call, result)
            "subscribeMsg" -> handleSubscribeMsgCall(call, result)
            "launchMiniProgram" -> handleLaunchMiniProgramCall(call, result)
            "openCustomerServiceChat" -> handleOpenCustomerServiceChat(call, result)
            "openBusinessView" -> handleOpenBusinessView(call, result)
            "openBusinessWebview" -> handleOpenBusinessWebview(call, result)
            "pay" -> handlePayCall(call, result)
            else -> result.notImplemented()
        }
    }

    private fun registerApp(call: MethodCall, result: Result) {
        val appId = call.argument<String>("appId") ?: run {
            result.error("INVALID_ARGUMENT", "appId is required", null)
            return
        }
        iwxapi = WXAPIFactory.createWXAPI(applicationContext, appId)
        iwxapi!!.registerApp(appId)
        result.success(null)
    }

    private fun handleInitialWXReq(call: MethodCall, result: Result) {
        if (handleInitialWXReqFlag.compareAndSet(false, true)) {
            val activity = activityPluginBinding?.activity
            if (activity != null) {
                val extra = WechatCallbackActivity.extraCallback(activity.intent)
                if (extra != null) {
                    iwxapi?.handleIntent(extra, iwxapiEventHandler)
                }
            }
        }
        // 幂等：第二次及后续调用直接返回成功，避免 PlatformException(FAILED)
        result.success(null)
    }

    private fun handleAuthCall(call: MethodCall, result: Result) {
        val req = SendAuth.Req()
        req.scope = call.argument("scope")
        req.state = call.argument("state")
        iwxapi?.sendReq(req)
        result.success(null)
    }

    private fun handleQRAuthCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startQrauth" -> {
                val appId = call.argument<String>("appId")!!
                val scope = call.argument<String>("scope")!!
                val noncestr = call.argument<String>("noncestr")!!
                val timestamp = call.argument<String>("timestamp")!!
                val signature = call.argument<String>("signature")!!
                qrauth.auth(appId, scope, noncestr, timestamp, signature, qrauthListener)
            }
            "stopQrauth" -> qrauth.stopAuth()
        }
        result.success(null)
    }

    private val qrauthListener = object : OAuthListener {
        override fun onAuthGotQrcode(qrcodeImgPath: String?, imgBuf: ByteArray?) {
            imgBuf?.let {
                channel?.invokeMethod("onAuthGotQrcode", mapOf("imageData" to it))
            }
        }

        override fun onQrcodeScanned() {
            channel?.invokeMethod("onAuthQrcodeScanned", null)
        }

        override fun onAuthFinish(errCode: OAuthErrCode?, authCode: String?) {
            channel?.invokeMethod("onAuthFinish", mapOf(
                "errorCode" to (errCode?.code ?: 0),
                "authCode" to (authCode ?: "")
            ))
        }
    }

    private fun handleOpenUrlCall(call: MethodCall, result: Result) {
        val req = OpenWebview.Req()
        req.url = call.argument("url")
        iwxapi?.sendReq(req)
        result.success(null)
    }

    private fun handleOpenRankListCall(call: MethodCall, result: Result) {
        val req = OpenRankList.Req()
        iwxapi?.sendReq(req)
        result.success(null)
    }

    private fun handleShareTextCall(call: MethodCall, result: Result) {
        val req = SendMessageToWX.Req()
        req.transaction = "${call.method}: ${System.currentTimeMillis()}"
        req.scene = call.argument("scene") ?: 0
        val text = call.argument<String>("text") ?: ""
        val message = WXMediaMessage()
        message.description = text.take(1024)
        val obj = WXTextObject()
        obj.text = text
        message.mediaObject = obj
        req.message = message
        iwxapi?.sendReq(req)
        result.success(null)
    }

    private fun handleShareMediaCall(call: MethodCall, result: Result) {
        val req = SendMessageToWX.Req()
        req.transaction = "${call.method}: ${System.currentTimeMillis()}"
        req.scene = call.argument<Int>("scene") ?: 0
        val message = WXMediaMessage()
        message.title = call.argument("title")
        message.description = call.argument("description")
        message.thumbData = call.argument("thumbData")

        when (call.method) {
            "shareImage" -> {
                val obj = WXImageObject()
                call.argument<ByteArray>("imageData")?.let { obj.imageData = it }
                call.argument<String>("imageUri")?.let { obj.imagePath = getShareFilePath(it) }
                message.mediaObject = obj
            }
            "shareFile" -> {
                val obj = WXFileObject()
                call.argument<ByteArray>("fileData")?.let { obj.fileData = it }
                call.argument<String>("fileUri")?.let { obj.filePath = getShareFilePath(it) }
                message.mediaObject = obj
            }
            "shareEmoji" -> {
                val obj = WXEmojiObject()
                call.argument<ByteArray>("emojiData")?.let { obj.emojiData = it }
                call.argument<String>("emojiUri")?.let { obj.emojiPath = getShareFilePath(it) }
                message.mediaObject = obj
            }
            "shareMusic" -> {
                val obj = WXMusicObject()
                obj.musicUrl = call.argument("musicUrl")
                obj.musicDataUrl = call.argument("musicDataUrl")
                obj.musicLowBandUrl = call.argument("musicLowBandUrl")
                obj.musicLowBandDataUrl = call.argument("musicLowBandDataUrl")
                message.mediaObject = obj
            }
            "shareVideo" -> {
                val obj = WXVideoObject()
                obj.videoUrl = call.argument("videoUrl")
                obj.videoLowBandUrl = call.argument("videoLowBandUrl")
                message.mediaObject = obj
            }
            "shareWebpage" -> {
                val obj = WXWebpageObject()
                obj.webpageUrl = call.argument("webpageUrl")
                message.mediaObject = obj
            }
            "shareMiniProgram" -> {
                val obj = WXMiniProgramObject()
                obj.webpageUrl = call.argument("webpageUrl")!!
                obj.userName = call.argument("username")!!
                obj.path = call.argument("path")
                call.argument<ByteArray>("hdImageData")?.let { message.thumbData = it }
                obj.withShareTicket = call.argument("withShareTicket") ?: false
                obj.miniprogramType = call.argument("type") ?: 0
                obj.disableforward = if (call.argument<Boolean>("disableForward") == true) 1 else 0
                message.mediaObject = obj
            }
        }
        req.message = message
        iwxapi?.sendReq(req)
        result.success(null)
    }

    private fun handleSubscribeMsgCall(call: MethodCall, result: Result) {
        val req = SubscribeMessage.Req()
        req.scene = call.argument("scene") ?: 0
        req.templateID = call.argument("templateId")
        req.reserved = call.argument("reserved")
        iwxapi?.sendReq(req)
        result.success(null)
    }

    private fun handleLaunchMiniProgramCall(call: MethodCall, result: Result) {
        val req = WXLaunchMiniProgram.Req()
        req.userName = call.argument("username")!!
        req.path = call.argument("path")
        req.miniprogramType = call.argument("type") ?: 0
        iwxapi?.sendReq(req)
        result.success(null)
    }

    private fun handleOpenCustomerServiceChat(call: MethodCall, result: Result) {
        val req = WXOpenCustomerServiceChat.Req()
        req.corpId = call.argument("corpId")!!
        req.url = call.argument("url")!!
        iwxapi?.sendReq(req)
        result.success(null)
    }

    private fun handleOpenBusinessView(call: MethodCall, result: Result) {
        val req = WXOpenBusinessView.Req()
        req.businessType = call.argument("businessType")!!
        req.query = call.argument("query")
        req.extInfo = call.argument("extInfo")
        iwxapi?.sendReq(req)
        result.success(null)
    }

    private fun handleOpenBusinessWebview(call: MethodCall, result: Result) {
        val req = WXOpenBusinessWebview.Req()
        req.businessType = call.argument("businessType") ?: 0
        req.queryInfo = call.argument("queryInfo")
        iwxapi?.sendReq(req)
        result.success(null)
    }

    private fun handlePayCall(call: MethodCall, result: Result) {
        val req = PayReq()
        req.appId = call.argument("appId")
        req.partnerId = call.argument("partnerId")
        req.prepayId = call.argument("prepayId")
        req.nonceStr = call.argument("noncestr")
        req.timeStamp = call.argument("timestamp")
        req.packageValue = call.argument("package")
        req.sign = call.argument("sign")
        iwxapi?.sendReq(req)
        result.success(null)
    }

    private fun getShareFilePath(fileUri: String): String {
        val ctx = applicationContext ?: return Uri.parse(fileUri).path ?: ""
        val api = iwxapi ?: return Uri.parse(fileUri).path ?: ""
        if (api.wxAppSupportAPI >= 0x27000D00 && Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
                val providerInfo = ctx.packageManager.getProviderInfo(
                    ComponentName(ctx, WechatFileProvider::class.java),
                    PackageManager.MATCH_DEFAULT_ONLY
                )
                val file = File(Uri.parse(fileUri).path ?: "")
                val shareFileUri = FileProvider.getUriForFile(ctx, providerInfo.authority, file)
                ctx.grantUriPermission("com.tencent.mm", shareFileUri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                return shareFileUri.toString()
            } catch (e: PackageManager.NameNotFoundException) {
                // ignore
            }
        }
        return Uri.parse(fileUri).path ?: ""
    }
}
