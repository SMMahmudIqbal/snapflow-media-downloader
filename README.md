# SnapFlow — Swiss Brutalist Multi-Platform Media Engine

> **Developed by S. M. Mahmud Iqbal**  
> **Production Web App:** [snapflow-media-downloader.vercel.app](https://snapflow-media-downloader.vercel.app)  
> **Latest Android APK Release:** [Download v1.0.0 APK (1.8 MB)](https://github.com/SMMahmudIqbal/snapflow-media-downloader/releases/download/v1.0.0/SnapFlow_v1.0.apk)

[![Live Web App](https://img.shields.io/badge/Live%20Engine-snapflow--media--downloader.vercel.app-DB4A2B?style=flat-square)](https://snapflow-media-downloader.vercel.app)
[![Android APK](https://img.shields.io/badge/Android%20APK-v1.0.0%20(1.8%20MB)-1E1E1E?style=flat-square&logo=android)](https://github.com/SMMahmudIqbal/snapflow-media-downloader/releases/download/v1.0.0/SnapFlow_v1.0.apk)
[![Author](https://img.shields.io/badge/Developed%20By-S.%20M.%20Mahmud%20Iqbal-6366f1?style=flat-square)](https://github.com/SMMahmudIqbal)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)

---

## Overview

SnapFlow is an open-source, ultra-fast media extraction and downloader suite inspired by the raw typographic energy of **Swiss Brutalism** and modern open-source media utilities. Unlike bloated, ad-ridden alternatives, SnapFlow is completely clean, private, ad-free, and high performance.

---

## Key Capabilities

1. **Integrated In-App Search Engine**:
   - Direct keyword querying across media platforms with zero URL copy-pasting required.
   - Built-in trending query chips (*Lofi Beats*, *Synthwave*, *NCS Music*, *Tech*, *Podcasts*).
   - High-contrast Swiss Brutalist cards featuring thumbnail previews, duration badges, channel info, view counts, and 1-click extraction triggers.

2. **Android System "Share to SnapFlow" Integration**:
   - Registered `android.intent.action.SEND` intent filter.
   - Tap "Share" on any video in YouTube, TikTok, Instagram, Twitter/X, or your web browser and pick SnapFlow—the app immediately launches and triggers stream extraction.

3. **In-App Web Explorer and Floating Stream Sniffer**:
   - Direct launchpad tiles for YouTube, TikTok, Instagram Reels, Twitter/X, SoundCloud, Facebook Watch, Reddit, and Twitch.
   - On Android: Browse within the app with a persistent native bottom toolbar featuring exit controls and stream sniffer triggers.
   - Floating Brutalist Sniffer Button with automatic clipboard link detection.

4. **Multi-Tier Fallback Extractor**:
   - Multi-client fallback (visionOS, Android, and web clients) ensuring resilient stream extraction even on cloud datacenter IPs.
   - Clear diagnostic notices for private, geo-locked, or removed media.

---

## Design System: Swiss Brutalism

- **Aesthetic**: Swiss Brutalist Poster Design
- **Palette**:
  - `Base (#E4E2DD)`: Warm tactile paper background
  - `Primary Ink (#1E1E1E)`: High-contrast brutalist framing and typography
  - `Accent Red (#DB4A2B)`: Vivid action highlight
  - `Warm Orange (#F8A348)` and `Soft Pink (#FF89A9)`: Atmospheric tones
- **Typography**:
  - **Headings**: *Clash Display* (700 weight, tight tracking `-0.05em`)
  - **Body / Meta**: *Satoshi* (400–500 weight)
- **Gradients**: Ambient radial blur blobs (120px blur) beneath typography.
- **Interactions**: Slide-up motion governed by `cubic-bezier(0.16, 1, 0.3, 1)` over 0.8s.

---

## Repository Structure

```text
snapflow-media-downloader/
├── android_app/                     # Native Android Kotlin App with WebView & Native Bridge
│   ├── app/src/main/
│   │   ├── AndroidManifest.xml      # Includes ACTION_MAIN & ACTION_SEND filters
│   │   ├── assets/                  # Embedded Swiss Brutalist offline UI assets
│   │   └── java/.../MainActivity.kt # Intent receiver, Native DownloadManager & Sniffer
│   └── build.gradle.kts             # Gradle build configuration
├── api/                             # Vercel Serverless Python Functions
│   ├── index.py                     # Main serverless entrypoint
│   ├── downloader.py                # Multi-tier yt-dlp media extraction engine
│   └── search.py                    # Zero-auth YouTube HTML & yt-dlp search engine
├── backend/                         # Local FastAPI Server
│   ├── main.py                      # Local development API
│   ├── downloader.py                # Media extraction engine
│   ├── search.py                    # Integrated search engine
│   └── static/                      # Static client assets
├── public/                          # Production Web Client (HTML5 / CSS3 / ES6)
│   ├── index.html                   # Swiss Brutalist UI (Developed by S. M. Mahmud Iqbal)
│   ├── style.css                    # Swiss Brutalism design system stylesheet
│   └── app.js                       # Search, Web Explorer, and Sniffer controller
├── release/                         # Release artifacts
│   └── SnapFlow_v1.0.apk            # Precompiled Android release binary (1.8 MB)
├── SnapFlow_v1.0.apk                # Root binary for 1-click access
├── vercel.json                      # Vercel deployment routes & config
└── README.md                        # Documentation & Project specification
```

---

## Deployment & Installation

### Android Installation
1. Download **[SnapFlow_v1.0.apk](https://github.com/SMMahmudIqbal/snapflow-media-downloader/releases/download/v1.0.0/SnapFlow_v1.0.apk)** directly to your Android device.
2. Tap to install (enable *Install from Unknown Sources* if prompted).
3. Open SnapFlow or share any video link from YouTube/TikTok directly to SnapFlow.

### Web Deployment
The web version is deployed live at **[snapflow-media-downloader.vercel.app](https://snapflow-media-downloader.vercel.app)**.

To deploy via Vercel:
```bash
vercel --prod
```

### Local Development
```bash
# Clone the repository
git clone https://github.com/SMMahmudIqbal/snapflow-media-downloader.git
cd snapflow-media-downloader

# Activate Python environment & run backend
.\backend\.venv\Scripts\Activate.ps1
python -m uvicorn backend.main:app --host 0.0.0.0 --port 8000 --reload
```

---

## Author and Attribution

**Developed by S. M. Mahmud Iqbal**  
- GitHub: [@SMMahmudIqbal](https://github.com/SMMahmudIqbal)

---

## License

This project is licensed under the MIT License.
