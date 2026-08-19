package com.zorbirey.bistportfoy;

import android.app.Activity;
import android.app.DownloadManager;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.Typeface;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.view.ViewGroup;
import android.view.WindowInsets;
import android.view.WindowInsetsController;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

public class MainActivity extends Activity {
    private FrameLayout root;
    private WebView webView;
    private ValueCallback<Uri[]> filePathCallback;
    private static final int FILE_CHOOSER_REQUEST = 1001;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        getWindow().setStatusBarColor(Color.rgb(219,233,227));
        getWindow().setNavigationBarColor(Color.BLACK);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            WindowInsetsController controller = getWindow().getInsetsController();
            if (controller != null) {
                controller.setSystemBarsAppearance(
                    0,
                    WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS
                );
            }
        }

        root = new FrameLayout(this);
        root.setBackgroundColor(Color.rgb(5,7,6));
        setContentView(root);

        showNativeSplash();
        new Handler(Looper.getMainLooper()).postDelayed(this::showApp, 3000);
    }

    private void showNativeSplash() {
        LinearLayout splash = new LinearLayout(this);
        splash.setOrientation(LinearLayout.VERTICAL);
        splash.setGravity(Gravity.CENTER);
        splash.setPadding(36, 36, 36, 36);
        splash.setBackgroundColor(Color.rgb(5,7,6));

        ImageView zeus = new ImageView(this);
        zeus.setImageResource(com.zorbirey.bistportfoy.R.drawable.zeus_splash);
        zeus.setAdjustViewBounds(true);
        LinearLayout.LayoutParams imgLp = new LinearLayout.LayoutParams(dp(220), dp(220));
        splash.addView(zeus, imgLp);

        TextView inspired = new TextView(this);
        inspired.setText("INSPIRED BY ZEUS");
        inspired.setTextColor(Color.rgb(228,189,79));
        inspired.setTextSize(21);
        inspired.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        inspired.setGravity(Gravity.CENTER);
        inspired.setLetterSpacing(0.12f);
        LinearLayout.LayoutParams t1 = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        t1.topMargin = dp(18);
        splash.addView(inspired, t1);

        TextView appName = new TextView(this);
        appName.setText("BİST TAKİP");
        appName.setTextColor(Color.WHITE);
        appName.setTextSize(14);
        appName.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        appName.setGravity(Gravity.CENTER);
        appName.setLetterSpacing(0.14f);
        LinearLayout.LayoutParams t2 = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        t2.topMargin = dp(10);
        splash.addView(appName, t2);

        root.addView(splash, new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
    }

    private void showApp() {
        root.removeAllViews();
        root.setBackgroundColor(Color.rgb(245,247,245));

        webView = new WebView(this);
        webView.setBackgroundColor(Color.rgb(245,247,245));
        FrameLayout.LayoutParams webLp = new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
        root.addView(webView, webLp);

        root.setOnApplyWindowInsetsListener((v, insets) -> {
            int left = 0, top = 0, right = 0, bottom = 0;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                android.graphics.Insets sys = insets.getInsets(WindowInsets.Type.systemBars() | WindowInsets.Type.displayCutout());
                left = sys.left; top = sys.top; right = sys.right; bottom = sys.bottom;
            } else {
                left = insets.getSystemWindowInsetLeft();
                top = insets.getSystemWindowInsetTop();
                right = insets.getSystemWindowInsetRight();
                bottom = insets.getSystemWindowInsetBottom();
            }
            if (webView != null) {
                FrameLayout.LayoutParams lp = (FrameLayout.LayoutParams) webView.getLayoutParams();
                lp.leftMargin = left;
                lp.topMargin = top;
                lp.rightMargin = right;
                lp.bottomMargin = bottom;
                webView.setLayoutParams(lp);
            }
            return insets;
        });
        root.requestApplyInsets();

        WebSettings s = webView.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setDatabaseEnabled(true);
        s.setAllowFileAccess(true);
        s.setAllowContentAccess(true);
        s.setCacheMode(WebSettings.LOAD_DEFAULT);

        webView.setWebViewClient(new WebViewClient());
        webView.setWebChromeClient(new WebChromeClient() {
            @Override public boolean onShowFileChooser(WebView view, ValueCallback<Uri[]> callback, FileChooserParams params) {
                if (filePathCallback != null) filePathCallback.onReceiveValue(null);
                filePathCallback = callback;
                try {
                    startActivityForResult(params.createIntent(), FILE_CHOOSER_REQUEST);
                    return true;
                } catch (Exception e) {
                    filePathCallback = null;
                    Toast.makeText(MainActivity.this, "Dosya seçici açılamadı", Toast.LENGTH_SHORT).show();
                    return false;
                }
            }
        });

        webView.setDownloadListener((url, userAgent, contentDisposition, mimeType, contentLength) -> {
            try {
                DownloadManager.Request request = new DownloadManager.Request(Uri.parse(url));
                request.setMimeType(mimeType);
                request.addRequestHeader("User-Agent", userAgent);
                request.setTitle("BIST Portföy yedeği");
                request.setDescription("Dosya indiriliyor");
                request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED);
                request.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, "bist-portfoy-yedek.json");
                ((DownloadManager)getSystemService(Context.DOWNLOAD_SERVICE)).enqueue(request);
            } catch (Exception e) {
                Toast.makeText(MainActivity.this, "Dosya indirilemedi", Toast.LENGTH_SHORT).show();
            }
        });

        webView.loadUrl("https://zorbirey.github.io/bist-portfoyum/?apk=android16");
    }

    private int dp(int value) {
        return Math.round(value * getResources().getDisplayMetrics().density);
    }

    @Override protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == FILE_CHOOSER_REQUEST) {
            Uri[] results = null;
            if (resultCode == Activity.RESULT_OK && data != null && data.getData() != null) results = new Uri[]{data.getData()};
            if (filePathCallback != null) {
                filePathCallback.onReceiveValue(results);
                filePathCallback = null;
            }
        }
    }

    @Override public void onBackPressed() {
        if (webView != null && webView.canGoBack()) webView.goBack();
        else super.onBackPressed();
    }
}
