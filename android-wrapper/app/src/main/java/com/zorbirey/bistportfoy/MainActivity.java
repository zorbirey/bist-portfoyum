package com.zorbirey.bistportfoy;

import android.app.Activity;
import android.app.DownloadManager;
import android.content.Context;
import android.content.Intent;
import android.content.res.Configuration;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
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
import android.webkit.RenderProcessGoneDetail;
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
    private static final int FILE_CHOOSER_REQUEST = 1001;
    private static final String APP_URL = "https://zorbirey.github.io/bist-portfoyum/?apk=android16";

    private final Handler handler = new Handler(Looper.getMainLooper());
    private FrameLayout root;
    private WebView webView;
    private ValueCallback<Uri[]> filePathCallback;
    private Runnable splashRunnable;
    private boolean destroyed = false;
    private boolean recoveringRenderer = false;
    private int lastLeft = -1, lastTop = -1, lastRight = -1, lastBottom = -1;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);

        try {
            configureSystemBars();
            root = new FrameLayout(this);
            root.setBackgroundColor(Color.rgb(5, 7, 6));
            setContentView(root);

            if (state == null) {
                showNativeSplashSafe();
                scheduleAppStart();
            } else {
                showApp(state);
            }
        } catch (Throwable startupError) {
            // Hiçbir görsel/resource problemi uygulamayı daha açılışta kapatmasın.
            try {
                if (root == null) {
                    root = new FrameLayout(this);
                    setContentView(root);
                }
                showFallbackSplash();
                scheduleAppStart();
            } catch (Throwable ignored) {
                // Son güvenlik katmanı: splash olmadan doğrudan uygulamayı açmayı dene.
                handler.postDelayed(() -> {
                    try { showApp(null); } catch (Throwable ignoredAgain) { }
                }, 250);
            }
        }
    }

    private void scheduleAppStart() {
        if (splashRunnable != null) handler.removeCallbacks(splashRunnable);
        splashRunnable = () -> {
            if (!destroyed && !isFinishing()) {
                try {
                    showApp(null);
                } catch (Throwable appStartError) {
                    showWebViewErrorScreen();
                }
            }
        };
        handler.postDelayed(splashRunnable, 3000);
    }

    private void configureSystemBars() {
        try { getWindow().setStatusBarColor(Color.rgb(219, 233, 227)); } catch (Throwable ignored) { }
        try { getWindow().setNavigationBarColor(Color.BLACK); } catch (Throwable ignored) { }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                WindowInsetsController controller = getWindow().getInsetsController();
                if (controller != null) {
                    controller.setSystemBarsAppearance(
                        0,
                        WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS
                    );
                }
            } catch (Throwable ignored) { }
        }
    }

    private void showNativeSplashSafe() {
        root.removeAllViews();
        root.setBackgroundColor(Color.rgb(5, 7, 6));

        ImageView fullSplash = new ImageView(this);
        fullSplash.setBackgroundColor(Color.rgb(5, 7, 6));
        fullSplash.setScaleType(ImageView.ScaleType.CENTER_INSIDE);

        boolean imageLoaded = false;
        Bitmap bitmap = null;
        try {
            BitmapFactory.Options options = new BitmapFactory.Options();
            options.inPreferredConfig = Bitmap.Config.RGB_565;
            options.inScaled = true;
            bitmap = BitmapFactory.decodeResource(getResources(), R.drawable.zeus_splash, options);
            if (bitmap != null && bitmap.getWidth() > 0 && bitmap.getHeight() > 0) {
                fullSplash.setImageBitmap(bitmap);
                imageLoaded = true;
            }
        } catch (Throwable ignored) {
            imageLoaded = false;
        }

        if (imageLoaded) {
            root.addView(fullSplash, new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            ));
        } else {
            // Zeus dosyası herhangi bir cihazda decode edilemezse uygulama artık kapanmaz.
            showFallbackSplash();
        }
    }

    private void showFallbackSplash() {
        if (root == null) return;
        root.removeAllViews();
        root.setBackgroundColor(Color.rgb(5, 7, 6));

        LinearLayout splash = new LinearLayout(this);
        splash.setOrientation(LinearLayout.VERTICAL);
        splash.setGravity(Gravity.CENTER);
        splash.setPadding(dp(28), dp(28), dp(28), dp(28));
        splash.setBackgroundColor(Color.rgb(5, 7, 6));

        TextView bolt = new TextView(this);
        bolt.setText("ϟ");
        bolt.setTextColor(Color.rgb(235, 190, 65));
        bolt.setTextSize(92);
        bolt.setGravity(Gravity.CENTER);
        bolt.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        splash.addView(bolt, new LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        ));

        TextView inspired = new TextView(this);
        inspired.setText("INSPIRED BY ZEUS");
        inspired.setTextColor(Color.rgb(228, 189, 79));
        inspired.setTextSize(21);
        inspired.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        inspired.setGravity(Gravity.CENTER);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) inspired.setLetterSpacing(0.12f);
        LinearLayout.LayoutParams t1 = new LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        );
        t1.topMargin = dp(18);
        splash.addView(inspired, t1);

        TextView appName = new TextView(this);
        appName.setText("BİST TAKİP");
        appName.setTextColor(Color.WHITE);
        appName.setTextSize(15);
        appName.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        appName.setGravity(Gravity.CENTER);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) appName.setLetterSpacing(0.14f);
        LinearLayout.LayoutParams t2 = new LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        );
        t2.topMargin = dp(12);
        splash.addView(appName, t2);

        root.addView(splash, new FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        ));
    }

    private void showApp(Bundle savedState) {
        if (destroyed || isFinishing() || root == null) return;

        destroyWebView();
        root.removeAllViews();
        root.setBackgroundColor(Color.rgb(245, 247, 245));

        try {
            // Activity context kullanmak WebView pencere/tema yaşam döngüsü için daha güvenlidir.
            webView = new WebView(this);
        } catch (Throwable webViewInitError) {
            showWebViewErrorScreen();
            return;
        }

        webView.setBackgroundColor(Color.rgb(245, 247, 245));
        FrameLayout.LayoutParams webLp = new FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        );
        root.addView(webView, webLp);

        applySafeInsets();
        configureWebView();

        boolean restored = false;
        if (savedState != null) {
            try {
                restored = webView.restoreState(savedState) != null;
            } catch (Throwable ignored) {
                restored = false;
            }
        }

        if (!restored) {
            try {
                webView.loadUrl(APP_URL);
            } catch (Throwable loadError) {
                showWebViewErrorScreen();
            }
        }
    }

    private void showWebViewErrorScreen() {
        if (destroyed || isFinishing() || root == null) return;
        try {
            destroyWebView();
            root.removeAllViews();
            root.setBackgroundColor(Color.rgb(245, 247, 245));

            LinearLayout box = new LinearLayout(this);
            box.setOrientation(LinearLayout.VERTICAL);
            box.setGravity(Gravity.CENTER);
            box.setPadding(dp(28), dp(28), dp(28), dp(28));

            TextView title = new TextView(this);
            title.setText("BİST TAKİP");
            title.setTextSize(24);
            title.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
            title.setTextColor(Color.BLACK);
            title.setGravity(Gravity.CENTER);
            box.addView(title);

            TextView message = new TextView(this);
            message.setText("Uygulama görüntüleme motoru başlatılamadı. Tekrar deneniyor.");
            message.setTextSize(16);
            message.setTextColor(Color.DKGRAY);
            message.setGravity(Gravity.CENTER);
            LinearLayout.LayoutParams mlp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            );
            mlp.topMargin = dp(16);
            box.addView(message, mlp);

            root.addView(box, new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            ));

            handler.postDelayed(() -> {
                if (!destroyed && !isFinishing()) {
                    try { showApp(null); } catch (Throwable ignored) { }
                }
            }, 1500);
        } catch (Throwable ignored) { }
    }

    private void applySafeInsets() {
        if (root == null) return;
        root.setOnApplyWindowInsetsListener((v, insets) -> {
            int left;
            int top;
            int right;
            int bottom;

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                android.graphics.Insets sys = insets.getInsets(
                    WindowInsets.Type.systemBars() | WindowInsets.Type.displayCutout()
                );
                left = sys.left;
                top = sys.top;
                right = sys.right;
                bottom = sys.bottom;
            } else {
                left = insets.getSystemWindowInsetLeft();
                top = insets.getSystemWindowInsetTop();
                right = insets.getSystemWindowInsetRight();
                bottom = insets.getSystemWindowInsetBottom();
            }

            if (webView != null &&
                (left != lastLeft || top != lastTop || right != lastRight || bottom != lastBottom)) {
                lastLeft = left;
                lastTop = top;
                lastRight = right;
                lastBottom = bottom;
                try {
                    FrameLayout.LayoutParams lp = (FrameLayout.LayoutParams) webView.getLayoutParams();
                    lp.leftMargin = left;
                    lp.topMargin = top;
                    lp.rightMargin = right;
                    lp.bottomMargin = bottom;
                    webView.setLayoutParams(lp);
                } catch (Throwable ignored) { }
            }
            return insets;
        });
        try { root.requestApplyInsets(); } catch (Throwable ignored) { }
    }

    private void configureWebView() {
        if (webView == null) return;

        try {
            WebSettings s = webView.getSettings();
            s.setJavaScriptEnabled(true);
            s.setDomStorageEnabled(true);
            s.setDatabaseEnabled(true);
            s.setAllowFileAccess(true);
            s.setAllowContentAccess(true);
            s.setJavaScriptCanOpenWindowsAutomatically(false);
            s.setSupportMultipleWindows(false);
            s.setCacheMode(WebSettings.LOAD_DEFAULT);
        } catch (Throwable settingsError) {
            showWebViewErrorScreen();
            return;
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try { webView.setRendererPriorityPolicy(WebView.RENDERER_PRIORITY_IMPORTANT, true); }
            catch (Throwable ignored) { }
        }

        webView.setWebViewClient(new WebViewClient() {
            @Override public boolean onRenderProcessGone(WebView view, RenderProcessGoneDetail detail) {
                recoverRenderer(detail != null && detail.didCrash());
                return true;
            }
        });

        webView.setWebChromeClient(new WebChromeClient() {
            @Override public boolean onShowFileChooser(
                WebView view,
                ValueCallback<Uri[]> callback,
                FileChooserParams params
            ) {
                if (filePathCallback != null) filePathCallback.onReceiveValue(null);
                filePathCallback = callback;
                try {
                    startActivityForResult(params.createIntent(), FILE_CHOOSER_REQUEST);
                    return true;
                } catch (Throwable e) {
                    filePathCallback = null;
                    Toast.makeText(MainActivity.this, "Dosya seçici açılamadı", Toast.LENGTH_SHORT).show();
                    return false;
                }
            }
        });

        webView.setDownloadListener((url, userAgent, contentDisposition, mimeType, contentLength) -> {
            try {
                Uri uri = Uri.parse(url);
                if (!"http".equalsIgnoreCase(uri.getScheme()) &&
                    !"https".equalsIgnoreCase(uri.getScheme())) {
                    Toast.makeText(MainActivity.this, "Bu indirme türü desteklenmiyor", Toast.LENGTH_SHORT).show();
                    return;
                }
                DownloadManager.Request request = new DownloadManager.Request(uri);
                request.setMimeType(mimeType);
                if (userAgent != null) request.addRequestHeader("User-Agent", userAgent);
                request.setTitle("BIST Portföy yedeği");
                request.setDescription("Dosya indiriliyor");
                request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED);
                request.setDestinationInExternalPublicDir(
                    Environment.DIRECTORY_DOWNLOADS,
                    "bist-portfoy-yedek.json"
                );
                DownloadManager manager = (DownloadManager) getSystemService(Context.DOWNLOAD_SERVICE);
                if (manager != null) manager.enqueue(request);
            } catch (Throwable e) {
                Toast.makeText(MainActivity.this, "Dosya indirilemedi", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void recoverRenderer(boolean crashed) {
        if (recoveringRenderer || destroyed || isFinishing()) return;
        recoveringRenderer = true;

        handler.post(() -> {
            if (destroyed || isFinishing()) return;
            destroyWebView();
            try {
                Toast.makeText(
                    MainActivity.this,
                    crashed ? "Görüntüleme motoru yeniden başlatıldı" : "Sayfa yeniden yükleniyor",
                    Toast.LENGTH_SHORT
                ).show();
            } catch (Throwable ignored) { }

            handler.postDelayed(() -> {
                recoveringRenderer = false;
                if (!destroyed && !isFinishing()) {
                    try { showApp(null); } catch (Throwable ignored) { showWebViewErrorScreen(); }
                }
            }, 500);
        });
    }

    private void destroyWebView() {
        if (webView == null) return;
        WebView old = webView;
        webView = null;

        try {
            if (old.getParent() instanceof ViewGroup) {
                ((ViewGroup) old.getParent()).removeView(old);
            }
        } catch (Throwable ignored) { }
        try { old.stopLoading(); } catch (Throwable ignored) { }
        try { old.setWebChromeClient(null); } catch (Throwable ignored) { }
        try { old.setWebViewClient(null); } catch (Throwable ignored) { }
        try { old.clearHistory(); } catch (Throwable ignored) { }
        try { old.removeAllViews(); } catch (Throwable ignored) { }
        try { old.destroy(); } catch (Throwable ignored) { }
    }

    private int dp(int value) {
        try {
            return Math.round(value * getResources().getDisplayMetrics().density);
        } catch (Throwable ignored) {
            return value;
        }
    }

    @Override protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == FILE_CHOOSER_REQUEST) {
            Uri[] results = null;
            if (resultCode == Activity.RESULT_OK && data != null && data.getData() != null) {
                results = new Uri[]{data.getData()};
            }
            if (filePathCallback != null) {
                try { filePathCallback.onReceiveValue(results); } catch (Throwable ignored) { }
                filePathCallback = null;
            }
        }
    }

    @Override protected void onResume() {
        super.onResume();
        if (webView != null) {
            try { webView.onResume(); } catch (Throwable ignored) { }
            try { webView.resumeTimers(); } catch (Throwable ignored) { }
        }
    }

    @Override protected void onPause() {
        if (webView != null) {
            try { webView.onPause(); } catch (Throwable ignored) { }
        }
        super.onPause();
    }

    @Override protected void onSaveInstanceState(Bundle outState) {
        if (webView != null) {
            try { webView.saveState(outState); } catch (Throwable ignored) { }
        }
        super.onSaveInstanceState(outState);
    }

    @Override public void onConfigurationChanged(Configuration newConfig) {
        super.onConfigurationChanged(newConfig);
        configureSystemBars();
        if (root != null) {
            try { root.requestApplyInsets(); } catch (Throwable ignored) { }
        }
    }

    @Override public void onLowMemory() {
        super.onLowMemory();
        if (webView != null) {
            try { webView.clearCache(false); } catch (Throwable ignored) { }
        }
    }

    @Override protected void onDestroy() {
        destroyed = true;
        if (splashRunnable != null) handler.removeCallbacks(splashRunnable);
        handler.removeCallbacksAndMessages(null);
        if (filePathCallback != null) {
            try { filePathCallback.onReceiveValue(null); } catch (Throwable ignored) { }
            filePathCallback = null;
        }
        destroyWebView();
        super.onDestroy();
    }

    @Override public void onBackPressed() {
        try {
            if (webView != null && webView.canGoBack()) webView.goBack();
            else super.onBackPressed();
        } catch (Throwable ignored) {
            super.onBackPressed();
        }
    }
}
