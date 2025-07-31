# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# BLE specific rules
-keep class com.bluez.ble.** { *; }
-keep class com.pauldemarco.flutter_blue_plus.** { *; }

# MQTT specific rules
-keep class org.eclipse.paho.** { *; }

# Prevent obfuscation of native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable implementations
-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Google Play Core - Fix for missing classes ERROR
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Flutter engine deferred components
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Model Viewer Plus
-keep class com.google.ar.** { *; }
-keep class com.google.android.filament.** { *; }
-dontwarn com.google.ar.**
-dontwarn com.google.android.filament.**

# Flutter Blue Plus updated
-keep class com.boskokg.flutter_blue_plus.** { *; }
-dontwarn com.boskokg.flutter_blue_plus.**

# Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# Path Provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Shared Preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Android Intent Plus
-keep class dev.fluttercommunity.plus.androidintent.** { *; }
-dontwarn dev.fluttercommunity.plus.androidintent.**

# Prevent warnings for missing classes that are not used in our app
-dontwarn javax.annotation.**
-dontwarn org.codehaus.mojo.animal_sniffer.IgnoreJRERequirement
-dontwarn okio.**
-dontwarn retrofit2.**
-dontwarn rx.**

# Keep generic signatures for better compatibility
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Keep line numbers for debugging crashes
-keepattributes SourceFile,LineNumberTable

# For crashes reporting tools
-renamesourcefileattribute SourceFile

# Alternative: If the above doesn't work, you can disable deferred components
# by adding this to your Flutter app's main AndroidManifest.xml:
# <meta-data android:name="io.flutter.embedding.android.EnableDeferredComponents" android:value="false" />

# Specific fix for Play Store split install issues
-keep public class com.google.android.play.core.splitcompat.SplitCompatApplication {
    public <init>(...);
}

-keep public class com.google.android.play.core.splitinstall.** {
    public <methods>;
}

-keep public class com.google.android.play.core.tasks.** {
    public <methods>;
}
