package com.binhnt.onepay_paygate_flutter;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import android.content.Intent;
import java.net.URISyntaxException;
import java.util.ArrayList;

import android.content.ActivityNotFoundException;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import android.app.Activity;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;

/** OnepayPaygateFlutterPlugin */
public class OnepayPaygateFlutterPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;
  private Activity activity;

  @Override
  public void onDetachedFromActivity() {
    activity = null;
  }

  @Override
  public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {
    activity = binding.getActivity();
  }

  @Override
  public void onAttachedToActivity(ActivityPluginBinding binding) {
    activity = binding.getActivity();
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    activity = null;
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "onepay_paygate_flutter");
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("getPlatformVersion")) {
      result.success("Android " + android.os.Build.VERSION.RELEASE);
    } else if (call.method.equals("openCustomURL")) {
      String url = ((ArrayList<String>)call.arguments()).get(0);
      gotoBankAppByUriIntent(url);
      result.success("");
    } else {
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }

  private void gotoBankAppByUriIntent(String url) {
    try {
      Intent intent = Intent.parseUri(url, Intent.URI_INTENT_SCHEME);
      intent.setAction(Intent.ACTION_VIEW);
      intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
      activity.startActivity(intent);
    } catch (URISyntaxException e) {
      e.printStackTrace();
    } catch (ActivityNotFoundException e) {
//      Toast.makeText(
//              OpPaymentActivity.this,
//              getString(R.string.no_app_found),
//              Toast.LENGTH_LONG)
//              .show();
    }
  }
}
