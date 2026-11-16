package com.tasjeel.app

import io.flutter.embedding.android.FlutterActivity

// هذا هو النظام الصحيح الحالي (Android v2 embedding).
// الخطأ "use of deleted Android v1 embedding" يحدث عندما يكون هناك ملف
// MainActivity قديم (عادة .java) يرث من io.flutter.app.FlutterActivity
// بدل io.flutter.embedding.android.FlutterActivity كما هنا.
class MainActivity : FlutterActivity()
