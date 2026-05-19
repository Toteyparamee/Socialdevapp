package com.socialdev.community_report

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        flutterEngine?.dartExecutor?.let {
            // notify flutter that a new intent arrived
        }
    }

    override fun onResume() {
        super.onResume()
        // Re-deliver intent on resume so flutter_appauth can read it
        intent?.let { setIntent(it) }
    }
}
