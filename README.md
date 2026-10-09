# SnapFlow — Swiss Brutalist Multi-Platform Media Engine

> **Developed by S. M. Mahmud Iqbal**

SnapFlow is an open-source, lightweight, and modern media extraction & downloader application inspired by the raw typographic energy of **Swiss Brutalism** and modern open-source media utilities (like Seal and NewPipe). Unlike ad-heavy third-party tools (such as Snaptube), SnapFlow is completely **clean, fast, ad-free, and privacy-respecting**.

---

## 🎨 Design System & Theme Specification
- **Aesthetic:** Swiss Brutalist Poster Design
- **Base Palette:**
  - `Base (#E4E2DD)`: Warm tactile paper background
  - `Primary Ink (#1E1E1E)`: High-contrast brutalist framing & typography
  - `Accent Red (#DB4A2B)`: Vivid action highlight
  - `Warm Orange (#F8A348)` & `Soft Pink (#FF89A9)`: Atmospheric tones
- **Typography:**
  - **Headings:** `Clash Display` (700 weight, tight tracking `-0.05em`, leading `0.75-0.85`)
  - **Body / Meta:** `Satoshi` (400–500 weight)
- **Gradients & Atmospherics:** Ambient radial blur blobs (120px blur) with `mix-blend-mode: multiply` beneath typography.
- **Micro-Interactions & Animation:** Slide-up motion governed by `cubic-bezier(0.16, 1, 0.3, 1)` over 0.8s.
- **Custom UI Elements:** 8px scrollbar (`#DB4A2B` thumb, `#E4E2DD` track) and `#DB4A2B` text selection highlight.

---

## 🌟 Key Highlights
- **Developed by:** S. M. Mahmud Iqbal
- **Multi-Platform Support:** Compatible with YouTube, TikTok, Instagram Reels, X (Twitter), Facebook, Reddit, Vimeo, and 1,000+ sites supported by `yt-dlp`.
- **Quality Options:** Select from 1080p Full HD, 720p HD, 480p, 360p, or high-bitrate MP3 / M4A audio.
- **Decoupled Architecture:**
  - **Backend API:** Built with **FastAPI** + **yt-dlp** for instant extractor updates without rebuilding mobile APKs when platforms change their APIs.
  - **Flutter Mobile App:** Swiss Brutalist mobile UI with real-time download progress tracking, clipboard detection, format picker bottom sheets, and offline library.
  - **Live Web Client & PWA:** Served directly by the backend at `http://localhost:8000`.

---

## 📁 Project Structure

```text
snapflow-media-downloader/
├── backend/
│   ├── .venv/                      # Isolated Python Virtual Environment
│   ├── main.py                     # FastAPI REST API & Static Web Server
│   ├── downloader.py               # Core extraction & streaming engine (yt-dlp)
│   ├── requirements.txt            # Python dependencies
│   └── static/                     # Swiss Brutalist Web UI / PWA test client
│       ├── index.html              # HTML5 interface (Developed by S. M. Mahmud Iqbal)
│       ├── style.css               # Swiss Brutalist stylesheet
│       └── app.js                  # Frontend client logic
├── flutter_app/                    # Complete Flutter Android/Cross-Platform app
│   ├── pubspec.yaml                # Flutter project configuration
│   ├── android/                    # Android manifest with network permissions
│   └── lib/
│       ├── main.dart               # Entrypoint (Developed by S. M. Mahmud Iqbal)
│       ├── models/                 # Media metadata & format models
│       ├── services/               # API service with download progress tracking
│       └── screens/                # Swiss Brutalist Home, Library, and About screens
└── README.md                       # Documentation & Setup instructions
```

---

## 🚀 Quick Start Guide

### 1. Launch the Backend Server

```bash
cd backend

# On Windows (PowerShell):
.\.venv\Scripts\Activate.ps1

# Start the FastAPI engine:
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

The server is accessible at:
- **Swiss Brutalist Web App:** [http://localhost:8000](http://localhost:8000)
- **API Documentation (Swagger UI):** [http://localhost:8000/docs](http://localhost:8000/docs)
- **Health Endpoint:** [http://localhost:8000/health](http://localhost:8000/health)

### 2. Run the Flutter Mobile App

```bash
cd flutter_app
flutter pub get
flutter run
```

---

## 👨‍💻 Author & Attribution
**Developed by S. M. Mahmud Iqbal**  
All rights reserved.
