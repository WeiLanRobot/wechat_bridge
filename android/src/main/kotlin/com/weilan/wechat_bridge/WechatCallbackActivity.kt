package com.weilan.wechat_bridge

import android.app.Activity
import android.content.Intent
import android.os.Build
import android.os.Bundle

class WechatCallbackActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            ?: return
        launchIntent.putExtra(KEY_WECHAT_CALLBACK, true)
        launchIntent.putExtra(KEY_WECHAT_EXTRA, intent)
        launchIntent.flags = Intent.FLAG_ACTIVITY_CLEAR_TOP
        startActivity(launchIntent)
        finish()
    }

    companion object {
        private const val KEY_WECHAT_CALLBACK = "wechat_callback"
        private const val KEY_WECHAT_EXTRA = "wechat_extra"

        fun extraCallback(intent: Intent): Intent? {
            if (intent.extras?.getBoolean(KEY_WECHAT_CALLBACK, false) == true) {
                return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableExtra(KEY_WECHAT_EXTRA, Intent::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra(KEY_WECHAT_EXTRA)
                }
            }
            return null
        }
    }
}
