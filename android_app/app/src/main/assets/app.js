/**
 * SnapFlow - Swiss Brutalist Interactive Controller
 * Author: Developed by S. M. Mahmud Iqbal
 */

document.addEventListener("DOMContentLoaded", () => {
  // Direct URL Elements
  const urlInput = document.getElementById("urlInput");
  const pasteBtn = document.getElementById("pasteBtn");
  const fetchBtn = document.getElementById("fetchBtn");
  const statusMsg = document.getElementById("statusMessage");
  const resultCard = document.getElementById("resultCard");
  const mediaThumbnail = document.getElementById("mediaThumbnail");
  const mediaDuration = document.getElementById("mediaDuration");
  const mediaPlatformBadge = document.getElementById("mediaPlatformBadge");
  const mediaTitle = document.getElementById("mediaTitle");
  const mediaAuthor = document.getElementById("mediaAuthor");
  const videoFormats = document.getElementById("videoFormats");
  const audioFormats = document.getElementById("audioFormats");
  const downloadsList = document.getElementById("downloadsList");
  const clearHistoryBtn = document.getElementById("clearHistoryBtn");
  const aboutBtn = document.getElementById("aboutBtn");
  const aboutModal = document.getElementById("aboutModal");
  const closeModalBtn = document.getElementById("closeModalBtn");
  const modalOkBtn = document.getElementById("modalOkBtn");
  const tabToggles = document.querySelectorAll(".tab-toggle");

  // Mode Switcher Elements
  const modeTabBtns = document.querySelectorAll(".mode-tab-btn");
  const panelUrl = document.getElementById("panelUrl");
  const panelSearch = document.getElementById("panelSearch");
  const panelExplore = document.getElementById("panelExplore");

  // Search Engine Elements
  const searchInput = document.getElementById("searchInput");
  const searchExecBtn = document.getElementById("searchExecBtn");
  const searchResultsSection = document.getElementById("searchResultsSection");
  const searchResultsGrid = document.getElementById("searchResultsGrid");
  const resultsCountLabel = document.getElementById("resultsCountLabel");
  const searchChips = document.querySelectorAll(".chip-item");

  // Web Explorer Elements
  const explorerUrlInput = document.getElementById("explorerUrlInput");
  const openExplorerBtn = document.getElementById("openExplorerBtn");
  const launchpadCards = document.querySelectorAll(".launchpad-card");
  const floatingSnifferBtn = document.getElementById("floatingSnifferBtn");

  let currentMediaData = null;
  let downloadHistory = JSON.parse(localStorage.getItem("snapflow_history") || "[]");

  const API_BASE = (window.location.origin && window.location.origin.startsWith("http"))
    ? ""
    : "https://snapflow-media-downloader.vercel.app";

  // Initial History
  renderHistory();

  // Mode Navigation Handler
  function switchMode(mode) {
    modeTabBtns.forEach(b => {
      b.classList.toggle("active", b.dataset.mode === mode);
    });

    if (panelUrl) panelUrl.style.display = (mode === "url") ? "block" : "none";
    if (panelSearch) panelSearch.style.display = (mode === "search") ? "block" : "none";
    if (panelExplore) panelExplore.style.display = (mode === "explore") ? "block" : "none";

    if (mode === "search" && searchInput) {
      setTimeout(() => searchInput.focus(), 150);
    }
  }

  modeTabBtns.forEach(btn => {
    btn.addEventListener("click", () => {
      switchMode(btn.dataset.mode);
    });
  });

  // Direct URL - Paste from clipboard
  if (pasteBtn) {
    pasteBtn.addEventListener("click", async () => {
      try {
        const text = await navigator.clipboard.readText();
        if (text) {
          urlInput.value = text.trim();
          urlInput.focus();
        }
      } catch (e) {
        showMessage("MANUAL INPUT: PASTE URL DIRECTLY INTO FIELD.", "info");
      }
    });
  }

  // Extract media button
  if (fetchBtn) {
    fetchBtn.addEventListener("click", () => {
      const url = urlInput.value.trim();
      if (!url) {
        showMessage("ERROR: SPECIFY A VALID RESOURCE URL.", "error");
        return;
      }
      extractMedia(url);
    });
  }

  // Enter key trigger for direct URL
  if (urlInput) {
    urlInput.addEventListener("keydown", (e) => {
      if (e.key === "Enter") {
        fetchBtn.click();
      }
    });
  }

  // ==========================================
  // IN-APP SEARCH ENGINE CONTROLLER
  // ==========================================
  async function performSearch(query) {
    const q = query.trim();
    if (!q) {
      showMessage("PLEASE ENTER A SEARCH KEYWORD OR ARTIST.", "error");
      return;
    }

    setSearchLoading(true);
    hideMessage();
    if (searchResultsSection) searchResultsSection.style.display = "block";
    if (searchResultsGrid) searchResultsGrid.innerHTML = '<div class="empty-notice">QUERYING GLOBAL MEDIA ARCHIVES...</div>';

    try {
      const res = await fetch(`${API_BASE}/api/search?q=${encodeURIComponent(q)}`);
      if (!res.ok) {
        throw new Error(`Search error status ${res.status}`);
      }
      const data = await res.json();
      renderSearchResults(data.results || [], q);
    } catch (err) {
      if (searchResultsGrid) {
        searchResultsGrid.innerHTML = `<div class="empty-notice">SEARCH FAILED: ${err.message}. TRY ANOTHER QUERY.</div>`;
      }
    } finally {
      setSearchLoading(false);
    }
  }

  function renderSearchResults(items, query) {
    if (!searchResultsGrid) return;
    if (resultsCountLabel) {
      resultsCountLabel.textContent = `FOUND ${items.length} RESULTS FOR "${query.toUpperCase()}"`;
    }

    if (!items || items.length === 0) {
      searchResultsGrid.innerHTML = '<div class="empty-notice">NO MEDIA FOUND FOR THIS QUERY. TRY BROADER KEYWORDS.</div>';
      return;
    }

    searchResultsGrid.innerHTML = "";
    items.forEach(item => {
      const card = document.createElement("div");
      card.className = "search-card";
      card.innerHTML = `
        <div class="search-card-thumb-wrap">
          <img class="search-card-thumb" src="${item.thumbnail}" alt="${escapeHtml(item.title)}" loading="lazy">
          <span class="search-card-duration">${item.duration || 'HD'}</span>
        </div>
        <div class="search-card-body">
          <h4 class="search-card-title" title="${escapeHtml(item.title)}">${escapeHtml(item.title)}</h4>
          <div class="search-card-meta">
            <span class="search-card-uploader">${escapeHtml(item.uploader || 'Creator')}</span>
            <span>${item.views || item.platform}</span>
          </div>
          <button class="search-card-extract-btn" type="button" data-url="${item.url}">
            <span>⚡ 1-CLICK EXTRACT</span>
          </button>
        </div>
      `;
      searchResultsGrid.appendChild(card);
    });

    // Attach 1-click extract listener to cards
    searchResultsGrid.querySelectorAll(".search-card-extract-btn").forEach(btn => {
      btn.addEventListener("click", () => {
        const targetUrl = btn.dataset.url;
        urlInput.value = targetUrl;
        switchMode("url");
        extractMedia(targetUrl);
        window.scrollTo({ top: resultCard.offsetTop - 40, behavior: "smooth" });
      });
    });
  }

  function setSearchLoading(isLoading) {
    if (!searchExecBtn) return;
    const label = searchExecBtn.querySelector(".search-btn-label");
    const spinner = searchExecBtn.querySelector(".search-spinner");
    if (isLoading) {
      searchExecBtn.disabled = true;
      if (label) label.style.display = "none";
      if (spinner) spinner.style.display = "block";
    } else {
      searchExecBtn.disabled = false;
      if (label) label.style.display = "inline";
      if (spinner) spinner.style.display = "none";
    }
  }

  if (searchExecBtn) {
    searchExecBtn.addEventListener("click", () => {
      performSearch(searchInput.value);
    });
  }

  if (searchInput) {
    searchInput.addEventListener("keydown", (e) => {
      if (e.key === "Enter") {
        performSearch(searchInput.value);
      }
    });
  }

  // Quick Trending Chips
  searchChips.forEach(chip => {
    chip.addEventListener("click", () => {
      const q = chip.dataset.query;
      if (searchInput) searchInput.value = q;
      performSearch(q);
    });
  });

  // ==========================================
  // WEB EXPLORER & STREAM SNIFFER
  // ==========================================
  function launchExplorerUrl(url) {
    if (!url) return;
    // Android native webview browser
    if (window.AndroidBridge && typeof window.AndroidBridge.openExplorer === "function") {
      window.AndroidBridge.openExplorer(url);
    } else {
      // In web browser: open in separate tab
      window.open(url, "_blank", "noopener,noreferrer");
      showMessage("BROWSER LAUNCHED: Copy video link and tap 'SNIFF MEDIA' to download!", "info");
    }
  }

  if (openExplorerBtn) {
    openExplorerBtn.addEventListener("click", () => {
      const url = explorerUrlInput.value.trim();
      if (url) launchExplorerUrl(url);
    });
  }

  launchpadCards.forEach(card => {
    card.addEventListener("click", () => {
      const url = card.dataset.url;
      if (url) launchExplorerUrl(url);
    });
  });

  // Floating Sniffer Button
  if (floatingSnifferBtn) {
    floatingSnifferBtn.addEventListener("click", async () => {
      try {
        const text = await navigator.clipboard.readText();
        const trimmed = (text || "").trim();
        if (trimmed.startsWith("http://") || trimmed.startsWith("https://")) {
          showMessage("CLIPBOARD LINK DETECTED: INITIALIZING EXTRACTION...", "info");
          urlInput.value = trimmed;
          switchMode("url");
          extractMedia(trimmed);
          return;
        }
      } catch (e) {
        // Clipboard read permission not granted or unsupported
      }

      // Prompt or switch
      const manual = prompt("Enter or paste video URL to sniff & extract:", urlInput.value || "");
      if (manual && manual.trim().startsWith("http")) {
        urlInput.value = manual.trim();
        switchMode("url");
        extractMedia(manual.trim());
      }
    });
  }

  // ==========================================
  // SHARED INTENT HANDLER (ANDROID SEND INTENT)
  // ==========================================
  window.handleSharedUrl = function(sharedUrl) {
    if (!sharedUrl) return;
    const cleanUrl = sharedUrl.trim();
    if (urlInput) urlInput.value = cleanUrl;
    switchMode("url");
    showMessage(`SHARED LINK RECEIVED: AUTO-PARSING ${cleanUrl}`, "info");
    extractMedia(cleanUrl);
  };

  // Check if Android app passed a pending shared URL on startup
  if (window.AndroidBridge && typeof window.AndroidBridge.getPendingSharedUrl === "function") {
    try {
      const pending = window.AndroidBridge.getPendingSharedUrl();
      if (pending && pending.length > 5) {
        window.handleSharedUrl(pending);
      }
    } catch (e) {
      console.warn("Could not check pending shared url:", e);
    }
  }

  // ==========================================
  // RESULT TABS SWITCHER (VIDEO / AUDIO)
  // ==========================================
  tabToggles.forEach(btn => {
    btn.addEventListener("click", () => {
      tabToggles.forEach(b => b.classList.remove("active"));
      btn.classList.add("active");
      const tab = btn.dataset.tab;
      if (tab === "video") {
        videoFormats.style.display = "flex";
        audioFormats.style.display = "none";
      } else {
        videoFormats.style.display = "none";
        audioFormats.style.display = "flex";
      }
    });
  });

  // About modal triggers
  if (aboutBtn) aboutBtn.addEventListener("click", () => aboutModal.style.display = "flex");
  if (closeModalBtn) closeModalBtn.addEventListener("click", () => aboutModal.style.display = "none");
  if (modalOkBtn) modalOkBtn.addEventListener("click", () => aboutModal.style.display = "none");
  if (aboutModal) {
    aboutModal.addEventListener("click", (e) => {
      if (e.target === aboutModal) aboutModal.style.display = "none";
    });
  }

  // Clear history
  if (clearHistoryBtn) {
    clearHistoryBtn.addEventListener("click", () => {
      downloadHistory = [];
      localStorage.removeItem("snapflow_history");
      renderHistory();
    });
  }

  // ==========================================
  // CORE EXTRACTION LOGIC
  // ==========================================
  async function extractMedia(url) {
    setLoading(true);
    hideMessage();
    resultCard.style.display = "none";

    try {
      const response = await fetch(`${API_BASE}/api/extract`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ url })
      });

      if (!response.ok) {
        const errData = await response.json().catch(() => ({}));
        throw new Error(errData.detail || `Server error code ${response.status}`);
      }

      const data = await response.json();
      currentMediaData = data;
      renderMedia(data);
    } catch (err) {
      let raw = err.message || 'COULD NOT PARSE STREAM';
      let msg = raw;
      if (raw.toLowerCase().includes("unavailable") || raw.toLowerCase().includes("not exist") || raw.toLowerCase().includes("removed") || raw.toLowerCase().includes("private") || raw.toLowerCase().includes("404")) {
        msg = "MEDIA UNAVAILABLE: This video does not exist, has been removed, or is set to private. Please verify your URL.";
      } else if (raw.toLowerCase().includes("confirm you're not a bot") || raw.toLowerCase().includes("sign in")) {
        msg = "STREAM NOTICE: YouTube verification required for this channel. Try our Android APK or another video link.";
      }
      showMessage(`NOTICE: ${msg}`, "error");
    } finally {
      setLoading(false);
    }
  }

  function renderMedia(data) {
    mediaThumbnail.src = data.thumbnail || "https://placehold.co/600x400/1E1E1E/E4E2DD?text=NO+THUMBNAIL";
    mediaDuration.textContent = data.duration_str || "LIVE";
    if (mediaPlatformBadge) {
      mediaPlatformBadge.textContent = (data.platform || "WEB").toUpperCase();
    }
    mediaTitle.textContent = (data.title || "UNTITLED MEDIA").toUpperCase();
    mediaAuthor.textContent = data.uploader || "UNKNOWN SOURCE";

    // Video formats catalog
    videoFormats.innerHTML = "";
    if (data.video_formats && data.video_formats.length > 0) {
      data.video_formats.forEach(f => {
        const row = document.createElement("div");
        row.className = "stream-row";
        row.innerHTML = `
          <div class="stream-meta">
            <span class="res-tag">${f.resolution}</span>
            <div>
              <div class="stream-spec-title">${f.label}</div>
              <div class="stream-spec-size">${f.filesize_str} // ${f.ext.toUpperCase()} STREAM</div>
            </div>
          </div>
          <button class="stream-action-btn" data-fid="${f.format_id}" data-type="video" data-label="${f.resolution}" data-direct="${encodeURIComponent(f.direct_url || '')}">
            DOWNLOAD
          </button>
        `;
        videoFormats.appendChild(row);
      });
    } else {
      videoFormats.innerHTML = '<div class="empty-notice">NO PROGRESSIVE VIDEO CHANNELS DISCOVERED. SWITCH TO AUDIO EXTRACTION.</div>';
    }

    // Audio formats catalog
    audioFormats.innerHTML = "";
    if (data.audio_formats && data.audio_formats.length > 0) {
      data.audio_formats.forEach(f => {
        const row = document.createElement("div");
        row.className = "stream-row";
        row.innerHTML = `
          <div class="stream-meta">
            <span class="res-tag audio-tag">MP3</span>
            <div>
              <div class="stream-spec-title">${f.label}</div>
              <div class="stream-spec-size">${f.filesize_str} // ${f.quality} BITRATE</div>
            </div>
          </div>
          <button class="stream-action-btn" data-fid="${f.format_id}" data-type="audio" data-label="Audio" data-direct="${encodeURIComponent(f.direct_url || '')}">
            EXTRACT
          </button>
        `;
        audioFormats.appendChild(row);
      });
    }

    // Attach download listeners
    document.querySelectorAll(".stream-action-btn").forEach(btn => {
      btn.addEventListener("click", () => {
        const fid = btn.dataset.fid;
        const isAudio = btn.dataset.type === "audio";
        const label = btn.dataset.label;
        const directUrl = decodeURIComponent(btn.dataset.direct || "");
        startDownload(data.url, fid, isAudio, data.title, label, directUrl);
      });
    });

    resultCard.style.display = "flex";
  }

  function startDownload(url, formatId, isAudio, title, label, directUrl) {
    const downloadEndpoint = `${API_BASE}/api/download?url=${encodeURIComponent(url)}&format_id=${encodeURIComponent(formatId)}&is_audio=${isAudio}`;
    
    // Determine target URL: prefer direct CDN stream URL if available
    const targetUrl = (directUrl && !directUrl.startsWith("manifest")) ? directUrl : downloadEndpoint;

    // Add to history
    const task = {
      id: Date.now(),
      title: title || "MEDIA FILE",
      type: isAudio ? "MP3 AUDIO" : `VIDEO (${label})`,
      time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      url: targetUrl
    };
    downloadHistory.unshift(task);
    if (downloadHistory.length > 20) downloadHistory.pop();
    localStorage.setItem("snapflow_history", JSON.stringify(downloadHistory));
    renderHistory();

    showMessage(`TRANSMISSION INITIALIZED: [${label}] ${title}`, "info");

    // 1. If running in Android App via Native AndroidBridge
    if (window.AndroidBridge && typeof window.AndroidBridge.downloadMedia === "function") {
      window.AndroidBridge.downloadMedia(targetUrl, title || "SnapFlow_Media", isAudio);
      return;
    }

    // 2. In web browser: trigger clean direct download / tab open
    const link = document.createElement("a");
    link.href = targetUrl;
    link.target = "_blank";
    link.rel = "noopener noreferrer";
    const cleanTitle = (title || "SnapFlow_Media").replace(/[^a-zA-Z0-9_-]/g, "_");
    link.download = `${cleanTitle}.${isAudio ? 'mp3' : 'mp4'}`;
    document.body.appendChild(link);
    link.click();
    setTimeout(() => {
      if (link.parentNode) link.parentNode.removeChild(link);
    }, 1000);
  }

  function renderHistory() {
    if (!downloadHistory || downloadHistory.length === 0) {
      downloadsList.innerHTML = '<div class="empty-notice">AWAITING FIRST EXTRACTION TASK.</div>';
      return;
    }

    downloadsList.innerHTML = "";
    downloadHistory.forEach(item => {
      const row = document.createElement("div");
      row.className = "history-task-row";
      row.innerHTML = `
        <div>
          <div class="task-title" title="${escapeHtml(item.title)}">${escapeHtml(item.title)}</div>
          <div class="task-tag">${item.type} // LOGGED AT ${item.time}</div>
        </div>
        <a href="${item.url}" class="task-redownload" target="_blank" rel="noopener noreferrer">SAVE</a>
      `;
      downloadsList.appendChild(row);
    });
  }

  function setLoading(isLoading) {
    const btnText = fetchBtn.querySelector(".btn-text");
    const spinner = fetchBtn.querySelector(".spinner");
    if (isLoading) {
      fetchBtn.disabled = true;
      btnText.style.display = "none";
      spinner.style.display = "block";
    } else {
      fetchBtn.disabled = false;
      btnText.style.display = "inline";
      spinner.style.display = "none";
    }
  }

  function showMessage(msg, type = "info") {
    statusMsg.textContent = msg;
    statusMsg.className = `status-box ${type}`;
    statusMsg.style.display = "block";
  }

  function hideMessage() {
    statusMsg.style.display = "none";
  }

  function escapeHtml(str) {
    if (!str) return "";
    return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
  }
});
