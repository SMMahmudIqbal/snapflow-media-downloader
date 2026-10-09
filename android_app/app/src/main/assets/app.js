/**
 * SnapFlow - Swiss Brutalist Interactive Controller
 * Author: Developed by S. M. Mahmud Iqbal
 */

document.addEventListener("DOMContentLoaded", () => {
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

  let currentMediaData = null;
  let downloadHistory = JSON.parse(localStorage.getItem("snapflow_history") || "[]");

  // Render initial history
  renderHistory();

  // Paste from clipboard
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

  // Extract media button
  fetchBtn.addEventListener("click", () => {
    const url = urlInput.value.trim();
    if (!url) {
      showMessage("ERROR: SPECIFY A VALID RESOURCE URL.", "error");
      return;
    }
    extractMedia(url);
  });

  // Enter key trigger
  urlInput.addEventListener("keydown", (e) => {
    if (e.key === "Enter") {
      fetchBtn.click();
    }
  });

  // Tabs Switcher
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
  aboutBtn.addEventListener("click", () => aboutModal.style.display = "flex");
  closeModalBtn.addEventListener("click", () => aboutModal.style.display = "none");
  modalOkBtn.addEventListener("click", () => aboutModal.style.display = "none");
  aboutModal.addEventListener("click", (e) => {
    if (e.target === aboutModal) aboutModal.style.display = "none";
  });

  // Clear history
  clearHistoryBtn.addEventListener("click", () => {
    downloadHistory = [];
    localStorage.removeItem("snapflow_history");
    renderHistory();
  });

  async function extractMedia(url) {
    setLoading(true);
    hideMessage();
    resultCard.style.display = "none";

    try {
      const response = await fetch("/api/extract", {
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
      showMessage(`EXTRACTION FAILED: ${err.message || 'COULD NOT PARSE STREAM'}`, "error");
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
    const downloadEndpoint = `/api/download?url=${encodeURIComponent(url)}&format_id=${encodeURIComponent(formatId)}&is_audio=${isAudio}`;
    
    // Add to history
    const task = {
      id: Date.now(),
      title: title || "MEDIA FILE",
      type: isAudio ? "MP3 AUDIO" : `VIDEO (${label})`,
      time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      url: directUrl || downloadEndpoint
    };
    downloadHistory.unshift(task);
    if (downloadHistory.length > 20) downloadHistory.pop();
    localStorage.setItem("snapflow_history", JSON.stringify(downloadHistory));
    renderHistory();

    showMessage(`TRANSMISSION INITIALIZED: [${label}] ${title}`, "info");
    
    // If direct stream URL is already known from metadata, download directly!
    if (directUrl && !directUrl.startsWith("manifest")) {
      window.open(directUrl, "_blank");
      return;
    }

    // Otherwise navigate to /api/download which issues a 307 redirect to the stream
    window.location.href = downloadEndpoint;
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
          <div class="task-title" title="${item.title}">${item.title}</div>
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
});
