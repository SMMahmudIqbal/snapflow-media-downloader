/**
 * SnapFlow - Swiss Brutalist Android Application
 * Developed by S. M. Mahmud Iqbal
 */
package com.snapflow.app

import android.app.Activity
import android.app.DownloadManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.net.Uri
import android.os.Bundle
import android.os.Environment
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.webkit.CookieManager
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.Toast

class MainActivity : Activity() {

    private lateinit var rootLayout: FrameLayout
    private lateinit var webView: WebView
    private lateinit var explorerToolbar: LinearLayout
    private var pendingSharedUrl: String? = null
    private var isExploring: Boolean = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        rootLayout = FrameLayout(this).apply {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
            setBackgroundColor(Color.parseColor("#E4E2DD"))
        }

        webView = WebView(this).apply {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        }
        rootLayout.addView(webView)

        setupExplorerToolbar()
        rootLayout.addView(explorerToolbar)

        setContentView(rootLayout)

        setupWebView()
        handleIntent(intent)

        webView.loadUrl("file:///android_asset/index.html")
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        if (Intent.ACTION_SEND == intent.action && intent.type?.startsWith("text/") == true) {
            val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT) ?: ""
            val urlRegex = Regex("""https?://[^\s]+""")
            val match = urlRegex.find(sharedText)
            val extracted = match?.value ?: sharedText.trim()
            if (extracted.startsWith("http://") || extracted.startsWith("https://")) {
                pendingSharedUrl = extracted
                notifyWebViewSharedUrl(extracted)
            }
        }
    }

    private fun notifyWebViewSharedUrl(url: String) {
        val safeUrl = url.replace("'", "\\'")
        runOnUiThread {
            if (isExploring) {
                exitExplorerMode()
            }
            webView.evaluateJavascript("if (window.handleSharedUrl) { window.handleSharedUrl('$safeUrl'); }", null)
        }
    }

    private fun setupExplorerToolbar() {
        explorerToolbar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            val lp = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = Gravity.BOTTOM
            }
            layoutParams = lp
            setBackgroundColor(Color.parseColor("#1E1E1E"))
            setPadding(24, 20, 24, 24)
            visibility = View.GONE
        }

        val btnExit = Button(this).apply {
            text = "✕ EXIT"
            setTextColor(Color.parseColor("#1E1E1E"))
            setBackgroundColor(Color.parseColor("#E4E2DD"))
            typeface = Typeface.DEFAULT_BOLD
            val lp = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1.0f).apply {
                setMargins(8, 0, 8, 0)
            }
            layoutParams = lp
            setOnClickListener {
                exitExplorerMode()
            }
        }

        val btnSniff = Button(this).apply {
            text = "⚡ EXTRACT MEDIA"
            setTextColor(Color.WHITE)
            setBackgroundColor(Color.parseColor("#DB4A2B"))
            typeface = Typeface.DEFAULT_BOLD
            val lp = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 2.0f).apply {
                setMargins(8, 0, 8, 0)
            }
            layoutParams = lp
            setOnClickListener {
                val currentUrl = webView.url ?: ""
                if (currentUrl.isNotEmpty() && !currentUrl.startsWith("file:")) {
                    exitExplorerMode()
                    notifyWebViewSharedUrl(currentUrl)
                } else {
                    Toast.makeText(this@MainActivity, "No media page detected.", Toast.LENGTH_SHORT).show()
                }
            }
        }

        explorerToolbar.addView(btnExit)
        explorerToolbar.addView(btnSniff)
    }

    fun openWebExplorer(url: String) {
        runOnUiThread {
            isExploring = true
            explorerToolbar.visibility = View.VISIBLE
            webView.loadUrl(url)
            Toast.makeText(this, "Browse page and tap 'EXTRACT MEDIA' when ready", Toast.LENGTH_LONG).show()
        }
    }

    fun exitExplorerMode() {
        runOnUiThread {
            isExploring = false
            explorerToolbar.visibility = View.GONE
            webView.loadUrl("file:///android_asset/index.html")
        }
    }

    private fun setupWebView() {
        val settings = webView.settings
        settings.javaScriptEnabled = true
        settings.domStorageEnabled = true
        settings.databaseEnabled = true
        settings.allowFileAccess = true
        settings.allowContentAccess = true
        settings.cacheMode = WebSettings.LOAD_DEFAULT
        settings.mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
        settings.useWideViewPort = true
        settings.loadWithOverviewMode = true
        settings.userAgentString = "Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36"

        webView.addJavascriptInterface(AndroidBridge(this), "AndroidBridge")

        webView.webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(view: WebView?, url: String?): Boolean {
                if (url != null && isExploring) {
                    view?.loadUrl(url)
                    return true
                }
                return false
            }

            override fun onPageFinished(view: WebView?, url: String?) {
                super.onPageFinished(view, url)
                if (url != null && url.startsWith("file:///android_asset/index.html")) {
                    pendingSharedUrl?.let { shared ->
                        notifyWebViewSharedUrl(shared)
                        pendingSharedUrl = null
                    }
                }
            }
        }

        webView.webChromeClient = WebChromeClient()

        webView.setDownloadListener { url, _, _, mimetype, _ ->
            startNativeDownload(url, null, mimetype)
        }
    }

    fun startNativeDownload(url: String, customTitle: String?, mimetype: String? = null) {
        try {
            val ext = if (url.contains(".mp3") || (mimetype != null && mimetype.contains("audio"))) ".mp3" else ".mp4"
            val cleanTitle = (customTitle ?: "SnapFlow_Media").replace(Regex("[^a-zA-Z0-9_-]"), "_")
            val filename = if (cleanTitle.endsWith(".mp4") || cleanTitle.endsWith(".mp3")) cleanTitle else "$cleanTitle$ext"

            val request = DownloadManager.Request(Uri.parse(url))
            if (mimetype != null) {
                request.setMimeType(mimetype)
            }
            val cookies = CookieManager.getInstance().getCookie(url)
            if (cookies != null) {
                request.addRequestHeader("cookie", cookies)
            }
            request.addRequestHeader("User-Agent", "Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36")
            request.setDescription("SnapFlow - Developed by S. M. Mahmud Iqbal")
            request.setTitle(filename)
            request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
            request.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, filename)

            val dm = getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
            dm.enqueue(request)
            runOnUiThread {
                Toast.makeText(this, "Downloading $filename to Downloads folder...", Toast.LENGTH_LONG).show()
            }
        } catch (e: Exception) {
            runOnUiThread {
                Toast.makeText(this, "Download error: ${e.message}", Toast.LENGTH_SHORT).show()
            }
        }
    }

    inner class AndroidBridge(private val context: Context) {
        @JavascriptInterface
        fun downloadMedia(url: String, title: String, isAudio: Boolean) {
            val mime = if (isAudio) "audio/mpeg" else "video/mp4"
            startNativeDownload(url, title, mime)
        }

        @JavascriptInterface
        fun openExplorer(url: String) {
            openWebExplorer(url)
        }

        @JavascriptInterface
        fun getPendingSharedUrl(): String {
            val url = pendingSharedUrl ?: ""
            pendingSharedUrl = null
            return url
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        if (isExploring) {
            if (webView.canGoBack()) {
                webView.goBack()
            } else {
                exitExplorerMode()
            }
        } else if (webView.canGoBack()) {
            webView.goBack()
        } else {
            super.onBackPressed()
        }
    }
}
