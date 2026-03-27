package com.bajaru.bajaru_admin_frontend

import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity is required by the truecaller_sdk plugin (v1.2.0).
// The plugin's onAttachedToActivity guard checks for FragmentActivity and only
// stores the Activity reference if this check passes. Using FlutterActivity
// causes "Activity not available" when initializing the SDK.
class MainActivity : FlutterFragmentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        // Pass null instead of savedInstanceState to prevent FlutterFragment from
        // trying to restore stale fragment state after Android kills the process.
        // Without this, returning from recents after process death causes a
        // race between fragment-state restoration and Dart isolate cold-start,
        // resulting in the app hanging indefinitely on the splash screen.
        super.onCreate(null)
    }
}
