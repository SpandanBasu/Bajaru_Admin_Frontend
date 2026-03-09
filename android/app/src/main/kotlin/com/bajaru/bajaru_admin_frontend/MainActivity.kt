package com.bajaru.bajaru_admin_frontend

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity is required by the truecaller_sdk plugin (v1.2.0).
// The plugin's onAttachedToActivity guard checks for FragmentActivity and only
// stores the Activity reference if this check passes. Using FlutterActivity
// causes "Activity not available" when initializing the SDK.
class MainActivity : FlutterFragmentActivity()
