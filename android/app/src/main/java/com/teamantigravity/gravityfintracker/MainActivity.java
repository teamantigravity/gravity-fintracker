package com.teamantigravity.gravityfintracker;

import io.flutter.embedding.android.FlutterFragmentActivity;

// local_auth's BiometricPrompt integration requires a FragmentActivity host.
// Using plain FlutterActivity here makes every authenticate() call throw.
public class MainActivity extends FlutterFragmentActivity {
}
