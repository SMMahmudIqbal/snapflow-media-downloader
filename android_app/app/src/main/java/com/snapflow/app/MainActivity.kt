/**
 * SnapFlow - Swiss Brutalist Android Application
 * Developed by S. M. Mahmud Iqbal
 */
package com.snapflow.app

import android.Manifest
import android.app.Activity
import android.app.DownloadManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Color
import android.graphics.Typeface
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.webkit.CookieManager
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.Toast
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL

class MainActivity : Activity() {

    private lateinit var rootLayout: FrameLayout
    private lateinit var webView: WebView
    private lateinit var explorerToolbar: LinearLayout
    private var pendingSharedUrl: String? = null
    private var isExploring: Boolean = false

    private val productionWebUrl = "https://snapflow-media-downloader.vercel.app"
    private val localAssetUrl = "file:///android_asset/index.html"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        checkAndRequestPermissions()

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

        // Attempt live web application first; falls back to offline assets automatically on error
        webView.loadUrl(productionWebUrl)
    }

    private fun checkAndRequestPermissions() {
        val permissionsToRequest = mutableListOf<String>()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                permissionsToRequest.add(Manifest.permission.POST_NOTIFICATIONS)
            }
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            if (checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
                permissionsToRequest.add(Manifest.permission.WRITE_EXTERNAL_STORAGE)
            }
        }

        if (permissionsToRequest.isNotEmpty()) {
            requestPermissions(permissionsToRequest.toTypedArray(), 101)
        }
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
                if (currentUrl.isNotEmpty() && !currentUrl.startsWith("file:") && !currentUrl.contains("snapflow-media-downloader")) {
                    exitExplorerMode()
                    notifyWebViewSharedUrl(currentUrl)
                } else {
                    Toast.makeText(this@MainActivity, "No target media page detected.", Toast.LENGTH_SHORT).show()
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
            webView.loadUrl(productionWebUrl)
        }
    }

    private fun setupWebView() {
        val settings = webView.settings
        settings.javaScriptEnabled = true
        settings.domStorageEnabled = true
        settings.databaseEnabled = true
        settings.allowFileAccess = true
        settings.allowContentAccess = true
        settings.allowFileAccessFromFileURLs = true
        settings.allowUniversalAccessFromFileURLs = true
        settings.cacheMode = WebSettings.LOAD_DEFAULT
        settings.mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
        settings.useWideViewPort = true
        settings.loadWithOverviewMode = true
        settings.mediaPlaybackRequiresUserGesture = false
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

            override fun onReceivedError(
                view: WebView?,
                request: WebResourceRequest?,
                error: WebResourceError?
            ) {
                super.onReceivedError(view, request, error)
                // If live web failed (e.g. offline), automatically fallback to local offline asset
                if (request?.isForMainFrame == true && !isExploring) {
                    val currentLoadingUrl = request.url.toString()
                    if (currentLoadingUrl.startsWith(productionWebUrl)) {
                        view?.loadUrl(localAssetUrl)
                    }
                }
            }

            override fun onPageFinished(view: WebView?, url: String?) {
                super.onPageFinished(view, url)
                pendingSharedUrl?.let { shared ->
                    notifyWebViewSharedUrl(shared)
                    pendingSharedUrl = null
                }
            }
        }

        webView.webChromeClient = WebChromeClient()

        webView.setDownloadListener { url, userAgent, contentDisposition, mimetype, _ ->
            startNativeDownload(url, null, mimetype)
        }
    }

    fun startNativeDownload(url: String, customTitle: String?, mimetype: String? = null) {
        try {
            val resolvedUrl = if (url.startsWith("/")) "$productionWebUrl$url" else url

            // If it's an external web helper URL, launch in browser directly
            if (resolvedUrl.contains("ssyoutube.com") || resolvedUrl.contains("y2mate") || resolvedUrl.contains("savefrom")) {
                val browserIntent = Intent(Intent.ACTION_VIEW, Uri.parse(resolvedUrl)).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(browserIntent)
                Toast.makeText(this, "Opening media downloader in browser...", Toast.LENGTH_SHORT).show()
                return
            }

            val ext = if (resolvedUrl.contains(".mp3") || (mimetype != null && mimetype.contains("audio"))) ".mp3" else ".mp4"
            val cleanTitle = (customTitle ?: "SnapFlow_Media").replace(Regex("[^a-zA-Z0-9_-]"), "_").take(50)
            val uniqueSuffix = (System.currentTimeMillis() % 100000).toString()
            val filename = "${cleanTitle}_$uniqueSuffix$ext"

            val request = DownloadManager.Request(Uri.parse(resolvedUrl)).apply {
                if (mimetype != null) {
                    setMimeType(mimetype)
                }
                val cookies = CookieManager.getInstance().getCookie(resolvedUrl)
                if (cookies != null) {
                    addRequestHeader("cookie", cookies)
                }
                addRequestHeader("User-Agent", "Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36")
                setDescription("SnapFlow - Developed by S. M. Mahmud Iqbal")
                setTitle(filename)
                setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
                setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, filename)
            }

            val dm = getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
            dm.enqueue(request)
            runOnUiThread {
                Toast.makeText(this, "Downloading to Downloads: $filename", Toast.LENGTH_LONG).show()
            }
        } catch (e: Exception) {
            // Robust fallback: open stream in browser / external download manager
            try {
                val fallbackIntent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(fallbackIntent)
                runOnUiThread {
                    Toast.makeText(this, "Opening stream in system downloader...", Toast.LENGTH_SHORT).show()
                }
            } catch (fallbackEx: Exception) {
                runOnUiThread {
                    Toast.makeText(this, "Download error: ${e.message}", Toast.LENGTH_LONG).show()
                }
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

        @JavascriptInterface
        fun nativeFetch(targetUrl: String, method: String, postData: String?): String {
            return try {
                val resolvedUrl = if (targetUrl.startsWith("/")) "$productionWebUrl$targetUrl" else targetUrl
                val url = URL(resolvedUrl)
                val conn = (url.openConnection() as HttpURLConnection).apply {
                    requestMethod = method.uppercase()
                    connectTimeout = 12000
                    readTimeout = 15000
                    setRequestProperty("User-Agent", "Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 SnapFlow")
                    setRequestProperty("Accept", "application/json")
                    if (!postData.isNullOrEmpty()) {
                        setRequestProperty("Content-Type", "application/json; charset=UTF-8")
                        doOutput = true
                        OutputStreamWriter(outputStream, "UTF-8").use { os ->
                            os.write(postData)
                            os.flush()
                        }
                    }
                }

                val responseCode = conn.responseCode
                val stream = if (responseCode in 200..299) conn.inputStream else conn.errorStream
                val responseText = BufferedReader(InputStreamReader(stream, "UTF-8")).use { reader ->
                    reader.readText()
                }
                responseText
            } catch (e: Exception) {
                "{\"error\": \"${e.message}\"}"
            }
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
