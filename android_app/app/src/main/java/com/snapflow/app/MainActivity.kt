/**
 * SnapFlow - Swiss Brutalist Android Application
 * Developed by S. M. Mahmud Iqbal
 */
package com.snapflow.app

import android.app.Activity
import android.app.DownloadManager
import android.content.Context
import android.net.Uri
import android.os.Bundle
import android.os.Environment
import android.webkit.CookieManager
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.Toast

class MainActivity : Activity() {

    private lateinit var webView: WebView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        webView = WebView(this)
        setContentView(webView)

        setupWebView()
        webView.loadUrl("file:///android_asset/index.html")
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

        webView.addJavascriptInterface(AndroidBridge(this), "AndroidBridge")

        webView.webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(view: WebView?, url: String?): Boolean {
                return false
            }
        }

        webView.webChromeClient = WebChromeClient()

        webView.setDownloadListener { url, userAgent, contentDisposition, mimetype, _ ->
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
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        if (webView.canGoBack()) {
            webView.goBack()
        } else {
            super.onBackPressed()
        }
    }
}
