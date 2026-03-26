import 'package:flutter/material.dart';
import 'package:wechat_bridge/wechat_bridge.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _platform = WechatBridgePlatform.instance;
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  String _status = '未注册';
  bool _isInstalled = false;

  @override
  void initState() {
    super.initState();
    _setupWechat();
    _listenResponses();
  }

  Future<void> _setupWechat() async {
    try {
      // 替换为你的微信 AppID 和 Universal Link
      await _platform.registerApp(
        appId: 'your_wechat_app_id',
        universalLink: 'https://your-domain.com/wechat/',
      );
      _isInstalled = await _platform.isInstalled();
      if (mounted) {
        setState(() {
          _status = _isInstalled ? '已注册，微信已安装' : '已注册，微信未安装';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = '注册失败: $e');
      }
    }
  }

  void _listenResponses() {
    _platform.respStream().listen((resp) {
      if (resp.isSuccessful) {
        debugPrint('操作成功: $resp');
      } else if (resp.isCancelled) {
        debugPrint('用户取消');
      } else {
        debugPrint('操作失败: ${resp.errorMsg}');
      }
    });
  }

  Future<void> _doAuth() async {
    if (!_isInstalled) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('请先安装微信')),
      );
      return;
    }
    try {
      await _platform.auth(
        scope: [WechatScope.kSNSApiUserInfo],
      );
    } catch (e) {
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('授权失败: $e')),
        );
      }
    }
  }

  Future<void> _shareWebpage() async {
    if (!_isInstalled) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('请先安装微信')),
      );
      return;
    }
    try {
      await _platform.shareWebpage(
        scene: WechatScene.kSession,
        title: '测试分享',
        description: '来自 wechat_bridge 的测试',
        webpageUrl: 'https://flutter.dev',
      );
    } catch (e) {
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('分享失败: $e')),
        );
      }
    }
  }

  Future<void> _doPay() async {
    if (!_isInstalled) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('请先安装微信')),
      );
      return;
    }
    // TODO: 从服务端获取支付参数
    // 支付参数需要从你的后端服务器获取，这里仅作示例
    try {
      await _platform.pay(
        appId: 'your_wechat_app_id',
        partnerId: 'partner_id_from_server',
        prepayId: 'prepay_id_from_server',
        package: 'Sign=WXPay',
        nonceStr: 'nonce_str_from_server',
        timeStamp: 'timestamp_from_server',
        sign: 'sign_from_server',
      );
    } catch (e) {
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('支付失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Wechat Bridge 示例'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_status, textAlign: TextAlign.center),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _doAuth,
                  child: const Text('微信登录'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _shareWebpage,
                  child: const Text('分享网页'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _doPay,
                  child: const Text('微信支付 0.01'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
